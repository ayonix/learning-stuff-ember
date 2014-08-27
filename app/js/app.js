App = Ember.Application.create({
	LOG_TRANSITIONS: true, 
});

App.Router.map(function() {
	this.resource('topics', function() {
	    this.route('new');
	    this.resource('topic', {path: ':id'}, function() {
		    this.resource('notes', function() {
		    	this.route('new');
		    	this.resource('note', {path: ':id'}, function() {
		    	});
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
	notes: DS.hasMany('note')
});

App.Note = DS.Model.extend({
	question: DS.attr('string'),
	answer: DS.attr('string'),
	topic: DS.belongsTo('topic')
});

App.IndexRoute = Ember.Route.extend({
  model: function() {
    return this.store.find('topic');
  }
});

App.TopicRoute = Ember.Route.extend({
	model: function(params) {
		return this.store.find('topic', params.id);
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
		save: function(params, model) {
			var self = this;
			var qu = this.get('question');
			var an = this.get('answer');
			var topic = this.get('topic');

			var note = this.store.createRecord('note', {
				question: qu,
				answer: an,
				topic: topic
			});

			note.save().then(function() {
				self.reset();
				// self.transitionToRoute('topic', topic);
			});
		}
	}
});
