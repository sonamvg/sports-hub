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
  end
end
