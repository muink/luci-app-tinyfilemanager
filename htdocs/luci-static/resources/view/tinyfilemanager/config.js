'use strict';
'require view';
'require fs';
'require uci';
'require ui';
'require form';

return view.extend({
//	handleSaveApply: null,
//	handleSave: null,
//	handleReset: null,

	load: function() {
	return Promise.all([
		L.resolveDefault(fs.stat('/usr/libexec/tinyfilemanager-update'), {}),
		uci.load('tinyfilemanager'),
	]);
	},

	render: function(res) {

		var m, s, o;

		m = new form.Map('tinyfilemanager');

		s = m.section(form.TypedSection, 'main');
		s.anonymous = true;

		o = s.option(form.Flag, 'use_auth', _('Enable Authentication'));
		o.rmempty = false;

		o = s.option(form.DynamicList, 'auth_users', _('Login user name and passwd hash'),
			_('You can generate new passwd in <b>File Manager -> Admin -> Help -> Generate new</b> or <a href="%s"><b>Here</b></a>.').format('https://tinyfilemanager.github.io/docs/pwd.html'));

		o.datatype = "list(string)";
		o.placeholder = 'user:$2y$10$cFk8K5VQJr...';
		o.default = 'admin:$2y$10$BewzfQXrlnUihprEgGt7ROMB9NigZcZkkwssIRYznF9fwMuObIZoa';
		o.optional = true;
		o.rmempty = false;
		o.depends('use_auth', '1');

		o = s.option(form.DynamicList, 'readonly_users', _('Readonly users'));
		o.datatype = "list(string)";
		o.placeholder = 'user';
		o.default = 'user';
		o.optional = true;
		o.rmempty = false;
		o.depends('use_auth', '1');

		o = s.option(form.Value, 'root_path', _('Home path'));
		o.datatype = 'directory';
		o.placeholder = '/var';
		o.optional = true;
		o.rmempty = true;

		o = s.option(form.ListValue, 'date_format', _('Date format'));
		o.value('d.m.o', _('DD.MM.YYYY'));
		o.value('d-m-o', _('DD-MM-YYYY'));
		o.value('d/m/o', _('DD/MM/YYYY'));
		o.value('j.n.o', _('D.M.YYYY'));
		o.value('j-n-o', _('D-M-YYYY'));
		o.value('j/n/o', _('D/M/YYYY'));
		o.value('o.m.d', _('YYYY.MM.DD'));
		o.value('o-m-d', _('YYYY-MM-DD'));
		o.value('o/m/d', _('YYYY/MM/DD'));
		o.value('o.n.j', _('YYYY.M.D'));
		o.value('o-n-j', _('YYYY-M-D'));
		o.value('o/n/j', _('YYYY/M/D'));
		o.default = 'd.m.o';
		o.rmempty = false;

		o = s.option(form.ListValue, 'time_format', _('Time format'));
		o.value('H:i:s', _('HH:mm:ss'));
		o.value('G:i:s', _('H:mm:ss'));
		o.value('A h:i:s', _('TT hh:mm:ss'));
		o.value('A g:i:s', _('TT h:mm:ss'));
		o.value('h:i:s A', _('hh:mm:ss TT'));
		o.value('g:i:s A', _('h:mm:ss TT'));
		o.default = 'H:i:s';
		o.rmempty = false;

		o = s.option(form.Flag, 'show_second', _('Show seconds in time'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'favicon_path', _('Favicon path'));
		o.datatype = 'file';
		o.placeholder = '/etc/tinyfilemanager/favicon.png';
		o.optional = true;
		o.rmempty = false;

		o = s.option(form.ListValue, 'online_viewer', _('Online Docs viewer'),
			_('Requires running on open network'));
		o.value('0', _('Disable'));
		o.value('google', _('Google Docs'));
		o.value('microsoft', _('Microsoft Web Apps'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Value, 'max_upload_size', _('Max upload size (MBytes)'));
		o.datatype = "and(uinteger,max(2048))";
		o.placeholder = '3';
		o.default = '25';
		o.rmempty = false;

		o = s.option(form.Flag, 'proxy_enabled', _('Enable proxy for updater'));
		o.rmempty = true;

		o = s.option(form.ListValue, 'proxy_protocol', _('Proxy Protocol'));
		o.value('http', 'HTTP');
		o.value('https', 'HTTPS');
		o.value('socks5', 'SOCKS5');
		o.default = 'socks5';
		o.rmempty = false;
		o.depends('proxy_enabled', '1');

		o = s.option(form.Value, 'proxy_server', _('Proxy Server'));
		o.datatype = "ipaddrport(1)";
		o.placeholder = '192.168.1.10:1080';
		o.rmempty = false;
		o.depends('proxy_enabled', '1');

		o = s.option(form.Button, '_check_update', _('Check update'));
		o.inputtitle = _('Check update');
		o.inputstyle = 'apply';
		o.onclick = function() {
			window.setTimeout(function() {
				window.location = window.location.href.split('#')[0];
			}, L.env.apply_display * 1000);

			return fs.exec('/etc/init.d/tinyfilemanager', ['check'])
				.catch(function(e) { ui.addNotification(null, E('p', e.message), 'error') });
		};

//		s = m.section(form.TypedSection, '_updater');
//		s.render = L.bind(function(view, section_id) {
//			return  E('div',{ 'class': 'cbi-section' }, [
//						E('button', {
//							'class': 'cbi-button cbi-button-action',
//							'click': ui.createHandlerFn(view, 'handleQueryVendor')
//						}, _('Check update')),
//
//						E('select', { 'class': 'cbi-input-select' }, [
//							E('option', { 'value': '2.4.7' }, '2.4.7'),
//							E('option', { 'value': '2.4.3' }, '2.4.3'),
//							E('option', { 'value': '2.4.1' }, '2.4.1')
//						])
//			]);
//		}, o, this);

		return m.render();
	}
});
