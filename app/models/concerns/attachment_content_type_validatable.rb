module AttachmentContentTypeValidatable
  extend ActiveSupport::Concern

  # Attachments larger than this are rejected without being read for
  # sniffing, so a huge upload can't be used to force large in-memory reads.
  MAX_SNIFFABLE_ATTACHMENT_SIZE = 10.megabytes

  private

  # Rails only records the content type the uploader's browser declared, which
  # is trivial to spoof. This sniffs the attachment's actual magic bytes via
  # marcel and checks THAT against the allow-list instead of trusting the
  # declared type.
  #
  # `attachment` is either a has_one_attached proxy (responds to `attached?`)
  # or a single ActiveStorage::Attachment record pulled from a
  # has_many_attached collection (already known to be attached, and has no
  # `attached?` method of its own).
  def attachment_content_type_allowed?(attachment, allowed_types)
    return true if attachment.respond_to?(:attached?) && !attachment.attached?

    blob = attachment.blob
    return false if blob.byte_size.to_i > MAX_SNIFFABLE_ATTACHMENT_SIZE

    io = attachment_sniff_source(attachment)
    return false if io.nil?

    # Deliberately omit `name:`/`declared_type:` — both are attacker-controlled
    # and Marcel falls back to them when the byte content is inconclusive,
    # which would defeat the point of sniffing in the first place.
    sniffed_type = Marcel::MimeType.for(io)
    io.rewind if io.respond_to?(:rewind)

    allowed_types.include?(sniffed_type)
  rescue ActiveStorage::FileNotFoundError
    false
  end

  # A freshly attached upload isn't written to the storage service until the
  # record is saved, so blob.download would raise ActiveStorage::FileNotFoundError
  # during validation on a new (or not-yet-saved) record. Read straight from the
  # pending upload in that case, and fall back to the blob once it's actually
  # persisted in storage.
  def attachment_sniff_source(attachment)
    blob = attachment.blob
    return StringIO.new(blob.download) if blob.persisted?

    pending_upload = pending_attachable_for(attachment)
    pending_upload = pending_upload[:io] if pending_upload.is_a?(Hash)

    pending_upload if pending_upload.respond_to?(:read)
  end

  # A has_one_attached change exposes the pending file directly via
  # `#attachable`. A has_many_attached change (CreateMany) holds one
  # `#attachable` per file instead, in the same order as its `#attachments` —
  # so the specific pending file for THIS attachment has to be looked up by
  # matching object identity against that parallel array.
  def pending_attachable_for(attachment)
    change = attachment.record.attachment_changes[attachment.name.to_s]
    return if change.nil?
    return change.attachable if change.respond_to?(:attachable)
    return unless change.respond_to?(:attachables)

    index = change.attachments.find_index { |candidate| candidate.equal?(attachment) }
    change.attachables[index] if index
  end
end
