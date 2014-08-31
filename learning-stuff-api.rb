require 'json'
require 'active_record'
require 'sinatra'
require 'sinatra/activerecord'

set :database, "sqlite3:stuff.db"

# Serve static files
set :public_folder, File.dirname(__FILE__) + '/app'

class Topic < ActiveRecord::Base
	has_many :notes

	validates :name, {uniqueness: true, length: {minimum: 1}}
end

class Note < ActiveRecord::Base
	before_validation :init
	belongs_to :topic

	validates :question, length: {minimum: 1}
	validates :answer, length: {minimum: 1}
	validates :topic, presence: true

	def init
		self.needs_learning = true if self.needs_learning.nil?
	end

	def as_hash
		return {
			id: self.id,
			question: self.question,
			answer: self.answer,
			topic: self.topic_id,
			needs_learning: self.needs_learning
		}
	end
end

before do
	response['Access-Control-Allow-Origin'] = '*'
	response['Access-Control-Allow-Headers'] = 'Content-Type'
end

get '/' do
	redirect '/index.html'
end

# TOPICS
options '/topics' do
	%w(GET POST PUT DELETE)
end

get '/topics' do 
	topics = Topic.all.includes(:notes)
	data = {topics: []}
	topics.each_with_index do |t, i|
		data[:topics][i] = t.attributes
		data[:topics][i][:notes] = t.notes.pluck(:id)
	end
	return data.to_json
end

post '/topics' do
	data = JSON.parse(request.body.read, symbolize_names: true)
	topic = Topic.new(data[:topic])
	if topic.save
		{topic: topic, notes: topic.notes}.to_json
	else 
		error 400
	end
end

get '/topics/:id' do
	topic = Topic.find(params[:id])
	notes = topic.notes.all
	derp = {topic: topic.attributes, notes: []}
	derp[:topic][:notes] = topic.notes.map(&:id)
	notes.each do |n| 
		derp[:notes] << n.as_hash
	end
	derp.to_json
end

put '/topics/:id' do
	topic = Topic.find(params[:id])
	data = JSON.parse(request.body.read, symbolize_names: true)
	topic.update(data[:topic])
	if topic.save
		{topic: topic}.to_json
	else
		error 400
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
	debug Note.find(params[:id])
	{notes: Note.find(params[:id])}.to_json
end

post '/notes' do
	note = Note.new
	data = JSON.parse(request.body.read, symbolize_names: true)
	topic = Topic.find(data[:note][:topic])

	note.question = data[:note][:question]
	note.answer = data[:note][:answer]

	topic.notes << note
	if note.save
		{note: note}.to_json
	else
		error 400
	end
end

put '/notes/:id' do
	note = Note.find(params[:id])
	data = JSON.parse(request.body.read, symbolize_names: true)
	data[:topic_id] = data[:note].delete(:topic)
	if note.update(data[:note])
		{note: note}.to_json
	else
		error 400
	end
end

delete '/notes/:id' do
	Note.find(params[:id]).destroy
end

def debug(obj)
	puts '#########'
	puts obj.inspect
	puts '#########'
end