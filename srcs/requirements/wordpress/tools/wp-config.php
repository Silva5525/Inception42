<?php

// ** MySQL settings 
define( 'DB_NAME', 'DB_NAME' );
define( 'DB_USER', 'DB_USER' );
define( 'DB_PASSWORD', 'DB_PWD' );
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

define( 'WP_ALLOW_REPAIR', true );

// Authentication Keys and Salts (will bie replaced with unique values from sh)
### SALT_PLACEHOLDER ###

// // Redis cache only for bonus
// define( 'WP_REDIS_HOST', 'radischen' );
// define( 'WP_REDIS_PORT', 6380 );

define( 'WP_CACHE', true );

// // Table prefix so with this we can have multiple wordpress installations in the same database
$table_prefix = 'wp_';

// // For developers: WordPress debugging mode.
define( 'WP_DEBUG', true );

// // Disable the plugin and theme editor
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
