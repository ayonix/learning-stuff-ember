require 'data_mapper'
require 'json'
require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/json'

# If you want the logs displayed you have to do this before the call to setup
DataMapper::Logger.new($stdout, :debug)

# An in-memory Sqlite3 connection:
DataMapper.setup(:default, 'sqlite:/tmp/db.db')

class Topic
	include DataMapper::Resource
	has n, :notes

	property :id, Serial
	property :name, String
end

class Note
	include DataMapper::Resource
	belongs_to :topic

	property :id, Serial
	property :question, String
	property :answer, String
end

# DataMapper.auto_migrate!
DataMapper.auto_upgrade!

namespace '/api/v1' do
	before do
		response['Access-Control-Allow-Origin'] = '*'
		response['Access-Control-Allow-Headers'] = 'Content-Type'
	end

	# TOPICS
	options '/topics' do
		%w(GET POST PUT DELETE)
	end

	get '/topics' do 
		json topics: Topic.all
	end

	post '/topics' do
		data = JSON.parse(request.body.read, symbolize_names: true)
		Topic.create(data[:topic])
	end

	get '/topics/:id' do
		json topic: Topic.get(params[:id])
	end

	put '/topics/:id' do
		topic = Topic.get(params[:id])
		data = JSON.parse(request.body.read, symbolize_names: true)
		topic.update(data[:topic])
		if topic.save
			return 200
		else
			return 500
		end
	end

	delete '/topics/:id' do
		Topic.get(params[:id]).destroy
	end

	# NOTES
	options '/notes' do
		%w(GET POST PUT DELETE)
	end

	get '/notes/:id' do 
		json notes: Note.get(params[:id])
	end

	post '/notes' do
		note = Note.new
		data = JSON.parse(request.body.read, symbolize_names: true)
		note.attributes = data[:note]
		topic = Topic.get(data[:note][:topic_id])
		topic.notes << note
		if topic.save
			return 200
		else
			return 500
		end
	end

	put '/notes/:id' do
		note = Note.get(params[:id])
		data = JSON.parse(request.body.read, symbolize_names: true)
		note.update(data[:note])
		note.save
	end

	delete '/notes/:id' do
		Note.get(params[:id]).destroy
	end
end