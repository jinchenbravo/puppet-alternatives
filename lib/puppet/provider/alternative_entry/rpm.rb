Puppet::Type.type(:alternative_entry).provide(:rpm) do

  confine    :osfamily => :redhat
  defaultfor :osfamily => :redhat

  commands :alternatives => '/usr/sbin/alternatives'

  mk_resource_methods

  def create
    alternatives('--install',
      @resource.value(:altlink),
      @resource.value(:altname),
      @resource.value(:name),
      @resource.value(:priority)
    )
  end

  def exists?
    if ! File.exist?('/var/lib/alternatives/' + @resource.value(:altname))
      false
    else
      File.foreach('/var/lib/alternatives/' + @resource.value(:altname)).grep(/#{@resource.value(:name).gsub("/", "\/")}/).any?
    end
  end

  def destroy
    alternatives('--remove', @resource.value(:altname), @resource.value(:name))
  end

  def self.instances
    entries = []    
    varlibfiles = Dir.glob('/var/lib/alternatives/*').map { |x| File.basename(x) }
    varlibfiles.each do |f|
     x = alternatives('--display', f).grep(/priority/)
     x.each do |p| 
       p.scan(/(.*) - priority ([[:digit:]]+)/) do |(path,priority)|
       altlink = File.readlines('/var/lib/alternatives/' + f)[1].chomp
       entries << new(:altname => f, :altlink => altlink, :name => path, :priority => priority)
       end
     end
   end
   entries
  end

  def self.prefetch(resources)

    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    create
    @property_hash.clear
  end

end
