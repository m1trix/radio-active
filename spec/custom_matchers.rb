RSpec::Matchers.define :have_table do |expected|
  match do |db|
    [expected] == db.select("SHOW TABLES LIKE '#{expected}'", []) do |row|
      handle do |tables|
        tables.push row[0]
      end
    end
  end
end

RSpec::Matchers.define :have_rows do |exepcted|
  actual = nil

  match do |(db, table)|
    sql = "SELECT * FROM #{table}"
    actual = db.select(sql, []) do |row|
      handle do |result|
        result.push row.to_a
      end
    end

    actual.size == expected.size

    actual.each do |row|
      expect(expected).to include row
    end
  end

  failure_message do |(db, table)|
    <<-STRING
Expected '#{table}' to have the following rows (in any order):

#{expected.map(&:to_s).join("\n")}

BUT GOT
    
#{actual.map(&:to_s).join("\n")}

    STRING
  end
end