require 'json'
require 'active_record'
require 'sinatra'
require 'sinatra/activerecord'

set :database, "sqlite3:stuff.db"

# Serve static files
set :public_folder, File.dirname(__FILE__) + '/app'

class Topic < ActiveRecord::Base
	has_many :notes
end

class Note < ActiveRecord::Base
	belongs_to :topic
end

	before do
		response['Access-Control-Allow-Origin'] = '*'
		response['Access-Control-Allow-Headers'] = 'Content-Type'
	end

	# TOPICS
	options '/topics' do
		%w(GET POST PUT DELETE)
	end

	get '/topics' do 
		topics = Topic.all.includes(:notes)
		return {topics: topics}.to_json
	end

	post '/topics' do
		data = JSON.parse(request.body.read, symbolize_names: true)
		topic = Topic.create(data[:topic])
		{topic: topic, notes: topic.notes}.to_json
	end

	get '/topics/:id' do
		topic = Topic.find(params[:id])
		derp = {topic: topic.attributes, notes: topic.notes}
		derp[:topic][:notes] = topic.notes.map(&:id)
		derp.to_json
	end

	put '/topics/:id' do
		topic = Topic.find(params[:id])
		data = JSON.parse(request.body.read, symbolize_names: true)
		topic.update(data[:topic])
		if topic.save
			{topic: topic}.to_json
		else
			status 500
		end
	end

	delete '/topics/:id' do
		Topic.find(params[:id]).destroy
	end

	# NOTES
	options '/notes' do
		%w(GET POST PUT DELETE)
	end

	get '/notes/:id' do 
		{notes: Note.get(params[:id])}.to_json
	end

	post '/notes' do
		note = Note.new
		data = JSON.parse(request.body.read, symbolize_names: true)
		topic = Topic.find(data[:note][:topic])

		note.question = data[:note][:question]
		note.answer = data[:note][:answer]

		topic.notes << note
		if topic.save
			{note: note}.to_json
		else
			status 500
		end
	end

	put '/notes/:id' do
		note = Note.get(params[:id])
		data = JSON.parse(request.body.read, symbolize_names: true)
		note.update(data[:note])
		note.save
	end

	delete '/notes/:id' do
		Note.find(params[:id]).destroy
	end