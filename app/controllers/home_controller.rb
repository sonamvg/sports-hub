class HomeController < ApplicationController
  def index
    @previous_competitions = [
      {
        name: "2025 U.S. Open Taekwondo Championship",
        dates: "Feb 14-16, 2025",
        location: "Reno, Nevada, United States",
        organizer: "USA Taekwondo",
        url: "https://www.usatkd.org/2025-u-s-open-taekwondo-championship"
      },
      {
        name: "Fujairah 2025 World Taekwondo Cadet Championships",
        dates: "May 10-14, 2025",
        location: "Fujairah, United Arab Emirates",
        organizer: "World Taekwondo",
        url: "https://results.worldtaekwondo.org/competitions/fujairah-2025-world-taekwondo-cadet-championships/results"
      },
      {
        name: "Charlotte 2025 World Taekwondo Grand Prix Challenge",
        dates: "Jun 13-15, 2025",
        location: "Charlotte, North Carolina, United States",
        organizer: "World Taekwondo",
        url: "https://www.worldtaekwondo.org/competition/view.html?mcd=U05&nid=142108&sc=in"
      },
      {
        name: "2025 U.S. National Championships",
        dates: "Jul 23-27, 2025",
        location: "Ontario, California, United States",
        organizer: "USA Taekwondo",
        url: "https://www.usatkd.org/2025-u-s-taekwondo-national-championships"
      },
      {
        name: "Wuxi 2025 World Taekwondo Championships",
        dates: "Oct 24-30, 2025",
        location: "Wuxi, Jiangsu, China",
        organizer: "World Taekwondo",
        url: "https://results.worldtaekwondo.org/competitions/wuxi-2025-world-taekwondo-championships/results"
      },
      {
        name: "Nairobi 2025 World Taekwondo Under 21 Championships",
        dates: "Dec 3-6, 2025",
        location: "Nairobi, Kenya",
        organizer: "World Taekwondo",
        url: "https://www.kenyau21wtchampionship2025.com/"
      }
    ]

    @sports_news = {
      domestic: [
        {
          title: "Khelo India and federation support expanded",
          note: "India approved a revamped Khelo India Scheme and enhanced assistance to National Sports Federations for the 2026-27 to 2030-31 cycle.",
          source: "PIB",
          url: "https://www.pib.gov.in/PressReleasePage.aspx?PRID=2292439&lang=1&reg=48"
        },
        {
          title: "SAI selection and training notices stay active",
          note: "Sports Authority of India continues publishing athlete selection trials, training-centre notices, and performance-support updates across sports.",
          source: "Sports Authority of India",
          url: "https://sportsauthorityofindia.gov.in/sai_new/news-archive"
        },
        {
          title: "Domestic taekwondo calendar remains busy",
          note: "The Taekwon-do Association of India event calendar lists state, national, seminar, grading, and international participation opportunities.",
          source: "TAI",
          url: "https://www.itfindia.org.in/events"
        }
      ],
      international: [
        {
          title: "World Taekwondo Grand Prix calendar continues",
          note: "World Taekwondo results list the 2026 Grand Prix sequence, including Rome, Muju, Paris, and the Astana Grand Prix Final.",
          source: "World Taekwondo",
          url: "https://results.worldtaekwondo.org/competitions?type=gp"
        },
        {
          title: "International event results are published globally",
          note: "The World Taekwondo competition tracker lists open championships, continental events, ranking events, and major international tournaments.",
          source: "World Taekwondo Results",
          url: "https://results.worldtaekwondo.org/competitions"
        },
        {
          title: "Upcoming hosts set through 2027",
          note: "World Taekwondo announced hosts for future Grand Prix, junior, cadet, poomsae, and women’s open events through 2027.",
          source: "World Taekwondo News",
          url: "https://www.worldtaekwondo.org/wtnews/view.html?mcd=C02&nid=142224"
        }
      ]
    }

    @taekwondo_blogs = [
      {
        title: "Traditional Taekwondo Ramblings",
        note: "Deep dives into Kukki Taekwondo history, traditions, practical applications, and training ideas.",
        url: "http://jungdokwan-taekwondo.blogspot.com/"
      },
      {
        title: "Little Black Belt",
        note: "Personal reflections, training stories, and martial arts lessons from a long-time taekwondo practitioner.",
        url: "https://littleblackbelt.com/"
      },
      {
        title: "SportsEdTV Taekwondo",
        note: "Instruction-focused taekwondo articles for athletes and coaches looking for practical training guidance.",
        url: "https://sportsedtv.com/blog/category/taekwondo/"
      },
      {
        title: "British Taekwondo News",
        note: "National governing body updates, safeguarding information, events, and member news from the United Kingdom.",
        url: "https://www.britishtaekwondo.org.uk/news/"
      },
      {
        title: "Grit & Glory Taekwondo Blog",
        note: "Parent-friendly articles about child development, first classes, belt progression, and youth confidence.",
        url: "https://ggtkd.com/blog"
      },
      {
        title: "Sun Lee Taekwondo Blog",
        note: "Academy-written pieces on respect, character development, competition teams, and life on the mat.",
        url: "https://sunleetaekwondo.com/blogs/news"
      }
    ]

    @taekwondo_videos = [
      {
        title: "413 R32 Men 80kg USA NICKOLAS C A ROU CRISTESCU M A",
        note: "World Taekwondo channel top video, listed around 1.19M views by vidIQ.",
        url: "https://www.youtube.com/results?search_query=413+R32+Men+80kg+USA+NICKOLAS+C+A+ROU+CRISTESCU+M+A"
      },
      {
        title: "232 SF M 80kg USA NICKOLAS Carl alan ITA ALESSIO Simone | Paris 2022 World Taekwondo Grand-Prix",
        note: "World Taekwondo channel top video, listed around 765K views by vidIQ.",
        url: "https://www.youtube.com/results?search_query=232+SF+M+80kg+USA+NICKOLAS+Carl+alan+ITA+ALESSIO+Simone+Paris+2022+World+Taekwondo+Grand-Prix"
      },
      {
        title: "307 R32 M 80kg TPE HUANG Y USA NICKOLAS C",
        note: "World Taekwondo channel top video, listed around 488K views by vidIQ.",
        url: "https://www.youtube.com/results?search_query=307+R32+M+80kg+TPE+HUANG+Y+USA+NICKOLAS+C"
      },
      {
        title: "233 M-58kg F JENDOUBI Mohamed khalil TUN vs JANG Jun KOR | Rome 2022 World Taekwondo GP",
        note: "World Taekwondo channel top video, listed around 335K views by vidIQ.",
        url: "https://www.youtube.com/results?search_query=233+M-58kg+F+JENDOUBI+Mohamed+khalil+TUN+vs+JANG+Jun+KOR+Rome+2022+World+Taekwondo+GP"
      },
      {
        title: "523 W-49kg QF KANG Bora KOR vs WONGPATTANAKIT Panipak THA | Guadalajara 2022 WT Championships",
        note: "World Taekwondo channel top video, listed around 334K views by vidIQ.",
        url: "https://www.youtube.com/results?search_query=523+W-49kg+QF+KANG+Bora+KOR+vs+WONGPATTANAKIT+Panipak+THA+Guadalajara+2022+WT+Championships"
      }
    ]
  end
end
