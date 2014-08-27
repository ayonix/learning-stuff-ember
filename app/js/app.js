App = Ember.Application.create();

// App.ApplicationStore = DS.Store.extend();

App.Router.map(function() {
	this.resource('topics', function() {
	    this.route('new');
	    this.route('show', {path: ':id'});
	    this.resource('notes', function() {
	    	this.route('new');
	    });
	  });
});

App.ApplicationAdapter = DS.RESTAdapter.extend({
  host: 'http://localhost:4567',
  namespace: 'api/v1'
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

App.TopicsShowRoute = Ember.Route.extend({
	model: function(params) {
		return this.store.find('topic', params.id);
	}
});

App.TopicsNewController = Ember.Controller.extend({
	actions: {
		save: function() {
			var name = this.get('name');

			var topic = this.store.createRecord('topic', {
				name: name
			});

			this.set('name', '');
			topic.save().then(function() {
				this.transitionToRoute('topics');
			}).catch(failure);
		}
	}
});

App.NotesNewController = Ember.Controller.extend({
	actions: {
		save: function() {
			var qu = this.get('question');
			var an = this.get('answer');

			var note = this.store.createRecord('note', {
				question: qu,
				answer: an,
			});

			this.set('question', '');
			this.set('answer', '');

			note.save().then(function() {
				this.transitionToRoute('topics');
			});
		}
	}
});

function failure(reason) {
	console.log(reason);
}