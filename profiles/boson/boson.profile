<?php


function boson_form_install_configure_form_alter(&$form, $form_state) {
  $form['site_information']['site_name']['#default_value'] = t('boson');
  $form['#submit'][] = '_wr_profile_install_configure_form_submit';
}

/**
 * Forms API submit for the site configuration form.
 */
function _wr_profile_install_configure_form_submit($form, &$form_state) {
  global $user;
  $sql_file = dirname(__FILE__).'/sample_content.sql';
  $count = _wr_profile_import_sql($sql_file);
  drupal_set_message("Your Boson Drupal installation was successful.");

  variable_set('site_name', $form_state['values']['site_name']);
  variable_set('site_mail', $form_state['values']['site_mail']);
  variable_set('date_default_timezone', $form_state['values']['date_default_timezone']);
  variable_set('site_default_country', $form_state['values']['site_default_country']);

  if ($form_state['values']['update_status_module'][1]) {
    module_enable(array('update'), FALSE);


    if ($form_state['values']['update_status_module'][2]) {
      variable_set('update_notify_emails', array($form_state['values']['account']['mail']));
    }
  }

  $enable = array(
	  'theme_default' => 'boson',
	  'admin_theme' => 'seven',
	  //'zen'
  );
  theme_enable($enable);

 
  // Disable the default Bartik theme
  theme_disable(array('bartik'));

  $account = user_load(1);
  $merge_data = array('init' => $form_state['values']['account']['mail'], 'roles' => !empty($account->roles) ? $account->roles : array(), 'status' => 1);
  user_save($account, array_merge($form_state['values']['account'], $merge_data));
  // Load global $user and perform final login tasks.
  $user = user_load(1);
  user_login_finalize();

  if (isset($form_state['values']['clean_url'])) {
    variable_set('clean_url', $form_state['values']['clean_url']);
  }

  // Record when this install ran.
  variable_set('install_time', $_SERVER['REQUEST_TIME']);

  $form_state['build_info']['args'][0]['parameters']['profile'] = 'standard';

}

function _wr_profile_import_sql($filename){
  global $databases;
  if (@mysql_connect($databases['default']['default']['host'], $databases['default']['default']['username'], $databases['default']['default']['password'])){
    mysql_select_db($databases['default']['default']['database']);
    $buffer='';
    $count=0;
    $handle = @fopen($filename, "r");
    if ($handle) {
      while (!feof($handle)) {
        $line = fgets($handle);
        $buffer.=$line;
        if(preg_match('|;$|', $line)){
          $count++;
          mysql_query(_wr_profile_prefixTables($buffer));
          $buffer='';
        }
      }
      fclose($handle);
    }
    mysql_close();
  }
  return $count;
}

function _wr_profile_prefixTables($sql) {
  global $databases;
  $prefix = $databases['default']['default']['prefix'];
  if (is_array($prefix)) {
    $defaultPrefix = isset($prefix['default']) ? $prefix['default'] : '';
    unset($prefix['default']);
    $prefixes = $prefix;
  } else {
    $defaultPrefix = $prefix;
    $prefixes = array();
  }	
  // Replace specific table prefixes first.
  foreach ($prefixes as $key => $val) {
    $sql = strtr($sql, array('dd_' . $key  => $val . $key));
  }
  // Then replace remaining tables with the default prefix.
  return strtr($sql, array('dd_' => $defaultPrefix ));
}





