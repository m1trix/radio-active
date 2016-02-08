require 'yaml'

tests = ['database', 'access', 'queue', 'youtube']

desc 'Run all tests'
task :tests do
  tests.each do |name|
    Rake::Task["test:#{name}"].invoke
  end
end

desc 'Run specific test'
namespace :test do
  tests.each do |name|
    task(name) do
      Rake::Task['test:run'].execute(name)
    end
  end

  task :run, :task_id do |t, name|
    Rake::Task['test:skeptic'].execute(name)
    Rake::Task['test:spec'].execute(name)
  end

  task :spec, :task_id do |t, name|
    system("bundle exec rspec ./spec/#{name}_spec.rb --require ./spec/root_spec.rb --color --format documentation") or exit(1)
  end

  task :skeptic, :task_id do |t, name|
    nesting = (name == 'database') ? 3 : 2
    opts = %W(
      --lines-per-method=8
      --line-length=80
      --max-nesting-depth=#{nesting}
      --methods-per-class=10
      --max-method-arity=3
      --check-syntax=true
      --no-semicolons=true
      --naming-conventions=true
      --no-global-variables=true
      --no-trailing-whitespace=true
      --english-words-for-names='json sql db username url uri'
      --spaces-around-operators=true
    ).join(' ')

    system("bundle exec skeptic #{opts} lib/radioactive/#{name}.rb") or exit(1)
  end
end
