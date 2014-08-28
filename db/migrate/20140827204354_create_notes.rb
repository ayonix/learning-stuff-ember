class CreateNotes < ActiveRecord::Migration
  def change
  	create_table :notes do |t|
  		t.string :question
  		t.string :answer
  		t.integer :topic_id
  		t.boolean :needs_learning
  		t.timestamps
  	end
  end
end
