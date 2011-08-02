# -*- coding: utf-8 -*-
# requrie 'date'
miquire :core, "serialthread"
Module.new do
  def self.boot
    plugin = Plugin::create(:fav_timeline)
    plugin.add_event(:boot) do |service|
      Plugin.call(:setting_tab_regist, main, 'ふぁぼ')
    end
    @thread = SerialThreadGroup.new
    # @thread.max = 10000
    plugin.add_event(:update) do |service, message|
      if UserConfig[:auto_fav] || UserConfig[:auto_rt]
        if UserConfig[:fav_users]
          UserConfig[:fav_users].split(',').each do |user|
            # SerialThreadGroup.new { users( user.strip, message ) }
            @thread.new { users( user.strip, message ) }
          end
        end
        if UserConfig[:fav_keywords]
          UserConfig[:fav_keywords].split(',').each do |key|
            @thread.new{ keywords( key.strip, message ) }
          end
        end
      end
    end
  end

  def self.users( target, msg )
    if !msg.empty?
      msg.each do |m|
        user = m.idname
        if user == target
          rt = m[:retweet]
          fav = m.favorite?
          #遅延させるよ
          delay_time(target) if !fav && !rt
          # ふぁぼるよ
          m.favorite(true) if !fav && !rt && UserConfig[:auto_fav]
          # リツイートするよ
          m.retweet if !rt && UserConfig[:auto_rt]
        end
      end
    end
  end

  def self.delay_time(target)
    sec = 0
    sec = UserConfig[:fav_lazy].to_i if !UserConfig[:fav_lazy].empty?
    puts "start->"+target+":#{sec}"+Time.now.to_s
    sleep(rand(sec).to_i) 
    puts 'end->'+target+":"+Time.now.to_s
  end

  def self.keywords( key, msg )
    if !msg.empty?
      msg.each do |m|
        if /#{key}/u =~ m.to_s
          delay_time(m.idname) if !m.favorite?
          m.favorite(true) if UserConfig[:auto_fav] && !m.favorite?
          m.retweet if UserConfig[:auto_rt] && !m[:retweet]
        end
      end
    end
  end

  def self.main
    box = Gtk::VBox.new(false)
    fav_u = Mtk.group("ふぁぼるよ",
                      Mtk.boolean(:auto_fav, "じどうふぁぼ"),
                      Mtk.boolean(:auto_rt, "じどうりついーと"),
                      Mtk.input(:fav_users,"ふぁぼるゆーざ"),
                      Mtk.input(:fav_keywords, "きーわーど"),
                      # Mtk.adjustment使いたいがなんか使えない
                      Mtk.input(:fav_lazy, "ちえん時間"))
    box.closeup(fav_u)
  end

  boot
end
