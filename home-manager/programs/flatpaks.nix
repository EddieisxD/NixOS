{ pkgs, ... }: {

  services.flatpak = {

    enable = false;

    packages = [  
      # { appId = "app.zen_browser.zen"; origin = "flathub"; }
      # { appId = "be.alexandervanhee.gradia"; origin = "flathub"; }
      # { appId = "com.adilhanney.saber"; origin = "flathub"; }
      # { appId = "com.authormore.penpotdesktop"; origin = "flathub"; }
      # { appId = "com.brave.Browser"; origin = "flathub"; }
      # { appId = "com.cherry_ai.CherryStudio"; origin = "flathub"; }
      # { appId = "com.collaboraoffice.Office"; origin = "flathub"; }
      # { appId = "com.discordapp.Discord"; origin = "flathub"; }
      # { appId = "com.enjoyingfoss.feeel"; origin = "flathub"; }
      # { appId = "com.gitbutler.gitbutler"; origin = "flathub"; }
      # { appId = "com.github.PintaProject.Pinta"; origin = "flathub"; }
      # { appId = "com.github.jeromerobert.pdfarranger"; origin = "flathub"; }
      # { appId = "com.github.johnfactotum.Foliate"; origin = "flathub"; }
      { appId = "com.github.tchx84.Flatseal"; origin = "flathub"; }
      # { appId = "com.github.ztefn.haguichi"; origin = "flathub"; }
      { appId = "com.heroicgameslauncher.hgl"; origin = "flathub"; }
      # { appId = "com.librumreader.librum"; origin = "flathub"; }
      # { appId = "com.logseq.Logseq"; origin = "flathub"; }
      { appId = "com.mattjakeman.ExtensionManager"; origin = "flathub"; }
      # { appId = "com.napster.napster-bigscreen-electron"; origin = "flathub"; }
      # { appId = "com.one_ware.OneWare"; origin = "flathub"; }
      # { appId = "com.protonvpn.www"; origin = "flathub"; }
      # { appId = "com.rafaelmardojai.Blanket"; origin = "flathub"; }
      # { appId = "com.ranfdev.DistroShelf"; origin = "flathub"; }
      # { appId = "com.rcloneui.RcloneUI"; origin = "flathub"; }
      # { appId = "com.rustdesk.RustDesk"; origin = "flathub"; }
      # { appId = "com.spotify.Client"; origin = "flathub"; }
      # { appId = "com.super_productivity.SuperProductivity"; origin = "flathub"; }
      # { appId = "com.usebottles.bottles"; origin = "flathub"; }
      # { appId = "com.valvesoftware.Steam"; origin = "flathub"; }
      # { appId = "de.haeckerfelix.Fragments"; origin = "flathub"; }
      # { appId = "de.leopoldluley.Clapgrep"; origin = "flathub"; }
      # { appId = "de.z_ray.OptimusUI"; origin = "flathub"; }
      # { appId = "dev.skynomads.Seabird"; origin = "flathub"; }
      # { appId = "dev.zed.Zed"; origin = "flathub"; }
      { appId = "garden.jamie.Morphosis"; origin = "flathub"; }
      # { appId = "info.febvre.Komikku"; origin = "flathub"; }
      # { appId = "io.anytype.anytype"; origin = "flathub"; }
      # { appId = "io.appflowy.AppFlowy"; origin = "flathub"; }
      # { appId = "io.beekeeperstudio.Studio"; origin = "flathub"; }
      # { appId = "io.github.alainm23.planify"; origin = "flathub"; }
      # { appId = "io.github.ellie_commons.jorts"; origin = "flathub"; }
      { appId = "io.github.flattool.Ignition"; origin = "flathub"; }
      { appId = "io.github.flattool.Warehouse"; origin = "flathub"; }
      # { appId = "io.github.getnf.embellish"; origin = "flathub"; }
      { appId = "io.github.giantpinkrobots.flatsweep"; origin = "flathub"; }
      # { appId = "io.github.kelvinnovais.Kasasa"; origin = "flathub"; }
      { appId = "io.github.kolunmi.Bazaar"; origin = "flathub"; }
      { appId = "io.github.plrigaux.sysd-manager"; origin = "flathub"; }
      # { appId = "io.github.ronniedroid.concessio"; origin = "flathub"; }
      # { appId = "io.github.zarestia_dev.rclone-manager"; origin = "flathub"; }
      # { appId = "io.gitlab.adhami3310.Impression"; origin = "flathub"; }
      # { appId = "io.missioncenter.MissionCenter"; origin = "flathub"; }
      # { appId = "io.podman_desktop.PodmanDesktop"; origin = "flathub"; }
      { appId = "it.mijorus.gearlever"; origin = "flathub"; }
      # { appId = "md.obsidian.Obsidian"; origin = "flathub"; }
      # { appId = "me.iepure.devtoolbox"; origin = "flathub"; }
      # { appId = "me.proton.Mail"; origin = "flathub"; }
      # { appId = "net.bontal.Catalyst"; origin = "flathub"; }
      # { appId = "net.cozic.joplin_desktop"; origin = "flathub"; }
      # { appId = "net.lutris.Lutris"; origin = "flathub"; }
      # { appId = "network.loki.Session"; origin = "flathub"; }
      # { appId = "org.chromium.Chromium"; origin = "flathub"; }
      # { appId = "org.freedesktop.Bustle"; origin = "flathub"; }
      # { appId = "org.geogebra.GeoGebra"; origin = "flathub"; }
      # { appId = "org.gnome.Boxes"; origin = "flathub"; }
      # { appId = "org.gnome.Calculator"; origin = "flathub"; }
      # { appId = "org.gnome.Calendar"; origin = "flathub"; }
      # { appId = "org.gnome.Characters"; origin = "flathub"; }
      # { appId = "org.gnome.Connections"; origin = "flathub"; }
      # { appId = "org.gnome.Contacts"; origin = "flathub"; }
      # { appId = "org.gnome.DejaDup"; origin = "flathub"; }
      # { appId = "org.gnome.FileRoller"; origin = "flathub"; }
      # { appId = "org.gnome.Firmware"; origin = "flathub"; }
      # { appId = "org.gnome.Fractal"; origin = "flathub"; }
      # { appId = "org.gnome.Logs"; origin = "flathub"; }
      # { appId = "org.gnome.Loupe"; origin = "flathub"; }
      # { appId = "org.gnome.Maps"; origin = "flathub"; }
      # { appId = "org.gnome.NautilusPreviewer"; origin = "flathub"; }
      # { appId = "org.gnome.Papers"; origin = "flathub"; }
      # { appId = "org.gnome.Showtime"; origin = "flathub"; }
      # { appId = "org.gnome.SimpleScan"; origin = "flathub"; }
      # { appId = "org.gnome.Snapshot"; origin = "flathub"; }
      # { appId = "org.gnome.TextEditor"; origin = "flathub"; }
      # { appId = "org.gnome.Weather"; origin = "flathub"; }
      # { appId = "org.gnome.baobab"; origin = "flathub"; }
      # { appId = "org.gnome.clocks"; origin = "flathub"; }
      # { appId = "org.gnome.dspy"; origin = "flathub"; }
      # { appId = "org.gnome.font-viewer"; origin = "flathub"; }
      # { appId = "org.gnome.gitlab.somas.Apostrophe"; origin = "flathub"; }
      # { appId = "org.js.nuclear.Nuclear"; origin = "flathub"; }
      # { appId = "org.libreoffice.LibreOffice"; origin = "flathub"; }
      # { appId = "org.mozilla.Thunderbird"; origin = "flathub"; }
      # { appId = "org.mozilla.firefox"; origin = "flathub"; }
      # { appId = "org.octave.Octave"; origin = "flathub"; }
      # { appId = "org.onlyoffice.desktopeditors"; origin = "flathub"; }
      # { appId = "org.pipewire.Helvum"; origin = "flathub"; }
      # { appId = "org.qbittorrent.qBittorrent"; origin = "flathub"; }
      # { appId = "org.remmina.Remmina"; origin = "flathub"; }
      # { appId = "org.telegram.desktop"; origin = "flathub"; }
      # { appId = "org.videolan.VLC"; origin = "flathub"; }
      # { appId = "org.zotero.Zotero"; origin = "flathub"; }
      # { appId = "page.tesk.Refine"; origin = "flathub"; }
      # { appId = "se.sjoerd.Graphs"; origin = "flathub"; }
    ];
  };
}
