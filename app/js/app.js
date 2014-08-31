App = Ember.Application.create({
	LOG_TRANSITIONS: true, 
});

App.Router.map(function() {
	this.resource('topics', function() {
		this.route('new');
		this.resource('topic', {path: ':topic_id'}, function() {
			this.resource('notes', function() {
				this.route('new');
				this.route('note', {path: ':note_id'});
			});
		});
	});
});

App.ApplicationAdapter = DS.RESTAdapter.extend({
	host: 'http://localhost:4567',
	// namespace: 'api/v1'
});

App.Topic = DS.Model.extend({
	name: DS.attr('string'),
	notes: DS.hasMany('note', {async: true}),

	random_note: function() {
		var self = this;
		var next = this.get('notes').then(function(notes) {
			var ns = notes.get('content');
			ns = ns.filterProperty('needs_learning', true);
			if (ns.length > 0) {
				return ns[Math.floor(Math.random() * ns.length)].id;
			} else {
				return -1;
			}
		});
		return next;
	}
});

App.Note = DS.Model.extend({
	question: DS.attr('string'),
	answer: DS.attr('string'),
	topic: DS.belongsTo('topic'),
	needs_learning: DS.attr('boolean')
});

App.IndexRoute = Ember.Route.extend({
	model: function() {
		return this.store.find('topic');
	}
});

App.TopicRoute = Ember.Route.extend({
	model: function(params) {
		return this.store.find('topic', params.topic_id);
	}
});

App.TopicController = Ember.ObjectController.extend({
	actions: {
		random_note: function() {
			var self = this;
			this.get('model').random_note().then(function(id) {
				if (id !== -1) {
					self.transitionToRoute('notes.note', id);
				} else {
					alert('All questions done');
				}
			});

		}
	}
});

App.TopicsNewController = Ember.Controller.extend({
	actions: {
		save: function() {
			var self = this;
			var name = this.get('name');

			var topic = this.store.createRecord('topic', {
				name: name
			});

			topic.save().then(function() {
				self.set('name', '');
				self.transitionToRoute('topic', topic);
			});
		}
	}
});

App.NotesNewRoute = Ember.Route.extend({
	model: function(){
		return {
			topic: this.modelFor('topic')
		};
	},
	setupController: function(controller, model) {
		controller.set('topic', model.topic);
	}
});

App.NotesNewController = Ember.Controller.extend({
	reset: function(){
		this.setProperties({
			question: "",
			answer: "",
		});
	}.on("init"),

	actions: {
		save: function(params) {
			var self = this;
			var qu = this.get('question');
			var an = this.get('answer');
			var topic = this.get('topic');

			var note = this.store.createRecord('note', {
				question: qu,
				answer: an,
				topic: topic,
				needs_learning: true
			});

			note.save().then(function() {
				self.reset();
				self.transitionToRoute('notes.index', topic);
			}).bind(this);
		}
	}
});

App.NotesIndexRoute = Ember.Route.extend({
	model: function(params) {
		var topic = this.modelFor('topic');
		return topic.get('notes');
	}
});

App.NotesNoteRoute = Ember.Route.extend({
	model: function(params) {
		return {
			note: this.store.find('note', params.note_id),
			topic: this.modelFor('topic'),
		}
	}
})

App.NotesNoteController = Ember.ObjectController.extend({
	reset: function() {
		this.set('isShowingAnswer', false);
	},
	nextNote: function() {
		var self = this;
		this.get('topic').random_note().then(function(id) {
			if (id !== -1) {
				self.transitionToRoute('notes.note', id);
			} else {
				alert('All questions done');
			}
		});
	},
	actions: {
		showAnswer: function(params) {
			this.set('isShowingAnswer', true);
		},
		markAsKnown: function(params) {
			var note = this.get('note').then(function(note) {
				note.set('needs_learning', false);
				note.save();
			});
			this.nextNote();
		},
		random_note: function(params) {
			this.nextNote();
		}
	}
});