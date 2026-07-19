<?php
/*
** Copyright (C) 2001-2026 Zabbix SIA
**
** This program is free software: you can redistribute it and/or modify it under the terms of
** the GNU Affero General Public License as published by the Free Software Foundation, version 3.
**
** This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
** without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
** See the GNU Affero General Public License for more details.
**
** You should have received a copy of the GNU Affero General Public License along with this program.
** If not, see <https://www.gnu.org/licenses/>.
**/


/**
 * A class for Zabbix re-branding.
 */
class CBrandHelper {
	private const DEFAULT_PRODUCT_NAME = 'Coirtx';
	private const DEFAULT_PRODUCT_FULL_NAME = 'Coirtx Monitoring';
	private const DEFAULT_COMPANY_NAME = 'Oirt SI';
	private const DEFAULT_VENDOR_URL = 'https://www.oirtsix.com/';
	
	const BRAND_CONFIG_FILE_PATH = '/../../../local/conf/brand.conf.php';

	public const LEGACY_FRONTEND_ENTRY = 'zabbix.php';
	public const FRONTEND_ENTRY = 'zabbix.php';

	/**
	 * Brand configuration array.
	 *
	 * @var array
	 */
	private static $config = [];

	/**
	 * Lazy configuration loading.
	 */
	private static function loadConfig() {
		if (!self::$config) {
			$config_file_path = realpath(dirname(__FILE__).self::BRAND_CONFIG_FILE_PATH);

			if (file_exists($config_file_path)) {
				self::$config = include $config_file_path;
				if (is_array(self::$config)) {
					self::$config['IS_REBRANDED'] = true;
				}
				else {
					self::$config = [];
				}
			}
		}
	}

	/**
	 * Get value by key from configuration (load configuration if needed).
	 *
	 * @param string $key      configuration key
	 * @param mixed  $default  default value
	 *
	 * @return mixed
	 */
	private static function getValue($key, $default = false) {
		self::loadConfig();

		return (array_key_exists($key, self::$config) ? self::$config[$key] : $default);
	}

	/**
	 * Is branding active ?
	 *
	 * @return boolean
	 */
	public static function isRebranded() {
		return self::getValue('IS_REBRANDED');
	}

        /**
         * Get product name.
         *
         * @return string
         */
	public static function getProductName(): string {
	    return self::getValue('BRAND_PRODUCT_NAME', self::DEFAULT_PRODUCT_NAME);
	}

        /**
         * Get full product name.
         *
         * @return string
         */
	public static function getProductFullName(): string {
	    return self::getValue('BRAND_PRODUCT_FULL_NAME', self::DEFAULT_PRODUCT_FULL_NAME);
	}

        /**
         * Get company name.
         *
         * @return string
         */
	public static function getCompanyName(): string {
	    return self::getValue('BRAND_COMPANY_NAME', self::DEFAULT_COMPANY_NAME);
	}

        /**
         * Get vendor URL.
         *
         * @return string
         */
	public static function getVendorUrl(): string {
	    return self::getValue('BRAND_VENDOR_URL', self::DEFAULT_VENDOR_URL);
	}

        /**
         * Get browser title.
         *
         * @param string $page_title
         *
         * @return string
         */
	public static function getBrowserTitle(string $page_title): string {
	    $product = self::getProductName();

	    return $page_title !== ''
        	? "{$page_title} - {$product}"
	        : $product;
	}

	/**
	 * Get help URL.
	 *
	 * @return string
	 */
	public static function getHelpUrl() {
		return self::getValue('BRAND_HELP_URL', 'https://www.oirtsix.com/documentation/'.
			(preg_match('/^\d+\.\d+/', ZABBIX_VERSION, $version) ? $version[0].'/' : '')
		);
	}

	/**
	 * Get logo of the specified type.
	 *
	 * @return string
	 */
	public static function getLogo(int $type): ?string {
		switch ($type) {
			case LOGO_TYPE_NORMAL:
				return self::getValue('BRAND_LOGO', null);

			case LOGO_TYPE_SIDEBAR:
				return self::getValue('BRAND_LOGO_SIDEBAR', null);

			case LOGO_TYPE_SIDEBAR_COMPACT:
				return self::getValue('BRAND_LOGO_SIDEBAR_COMPACT', null);
		}

		return null;
	}

	/**
	 * Get footer content.
	 *
	 * @param boolean $with_version
	 *
	 * @return array
	 */
	public static function getFooterContent($with_version) {
		$footer = self::getValue(
			'BRAND_FOOTER',
			[
				$with_version ? self::getProductName().' '.ZABBIX_VERSION.'. ' : null,
				COPYR(), ' '.ZABBIX_COPYRIGHT_FROM, NDASH(), ZABBIX_COPYRIGHT_TO.', ',
				(new CLink(self::getCompanyName(), self::getVendorUrl()))
					->addClass(ZBX_STYLE_GREY)
					->addClass(ZBX_STYLE_LINK_ALT)
					->setTarget('_blank')
			]
		);

		if (!is_array($footer)) {
			$footer = [$footer];
		}

		return $footer;
	}
}
