import Foundation

/// Centralized keys for `Localizable.strings` (en / ru / kk).
enum L10n {
    private static func tr(_ key: String) -> String {
        let bundle = LanguageStoreBootstrap.bundle
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    enum Auth {
        static var start: String { tr("auth_start") }
        static var loginTitle: String { tr("auth_login_title") }
        static var registerTitle: String { tr("auth_register_title") }
        static var email: String { tr("auth_email") }
        static var password: String { tr("auth_password") }
        static var noAccount: String { tr("auth_no_account") }
        static var haveAccount: String { tr("auth_have_account") }
        static var forgotPassword: String { tr("auth_forgot_password") }
        static var login: String { tr("auth_login") }
        static var register: String { tr("auth_register") }
        static var termsPrefix: String { tr("auth_terms_prefix") }
        static var privacy: String { tr("auth_privacy") }
        static var termsAnd: String { tr("auth_terms_and") }
        static var terms: String { tr("auth_terms") }
        static var termsSuffix: String { tr("auth_terms_suffix") }
        static var errorGeneric: String { tr("auth_error_generic") }
        static var confirmEmail: String { tr("auth_confirm_email") }
        static var forgotTitle: String { tr("auth_forgot_title") }
        static var forgotHintEmpty: String { tr("auth_forgot_hint_empty") }
        static var forgotHintFormat: String { tr("auth_forgot_hint_format") }
        static var forgotResend: String { tr("auth_forgot_resend") }
        static var forgotSubmit: String { tr("auth_forgot_submit") }
        static var forgotCodeSent: String { tr("auth_forgot_code_sent") }
        static var forgotNeedEmail: String { tr("auth_forgot_need_email") }
        static var newPasswordTitle: String { tr("auth_new_password_title") }
        static var newPassword: String { tr("auth_new_password") }
        static var confirmPassword: String { tr("auth_confirm_password") }
        static var savePassword: String { tr("auth_save_password") }
        static var passwordMismatch: String { tr("auth_password_mismatch") }
        static var mailPopupTitle: String { tr("auth_mail_popup_title") }
        static var mailPopupBody: String { tr("auth_mail_popup_body") }
        static var mailPopupOK: String { tr("auth_mail_popup_ok") }
    }

    enum Tab {
        static var scan: String { tr("tab_scan") }
        static var home: String { tr("tab_home") }
        static var heart: String { tr("tab_heart") }
        static var spo2: String { tr("tab_spo2") }
        static var temp: String { tr("tab_temp") }
        static var vitals: String { tr("tab_vitals") }
        static var ecg: String { tr("tab_ecg") }
        static var micro: String { tr("tab_micro") }
        static var settings: String { tr("tab_settings") }
        static var metrics: String { tr("tab_metrics") }
        static var activity: String { tr("tab_activity") }
        static var goals: String { tr("tab_goals") }
        static var profile: String { tr("tab_profile") }
    }

    enum Placeholder {
        static var activitySub: String { tr("ph_activity_sub") }
        static var goalsSub: String { tr("ph_goals_sub") }
    }

    enum ProfileSetup {
        static var stepFormat: String { tr("ps_step_format") }
        static var back: String { tr("ps_back") }
        static var next: String { tr("ps_next") }
        static var done: String { tr("ps_done") }
        static var cancel: String { tr("ps_cancel") }
        static var sheetDone: String { tr("ps_sheet_done") }
        static var nameTitle: String { tr("ps_name_title") }
        static var nameSub: String { tr("ps_name_sub") }
        static var namePlaceholder: String { tr("ps_name_placeholder") }
        static var sectionProfile: String { tr("ps_section_profile") }
        static var genderTitle: String { tr("ps_gender_title") }
        static var genderSub: String { tr("ps_gender_sub") }
        static var genderMale: String { tr("ps_gender_male") }
        static var genderFemale: String { tr("ps_gender_female") }
        static var genderUnspecified: String { tr("ps_gender_unspecified") }
        static var ageTitle: String { tr("ps_age_title") }
        static var ageSub: String { tr("ps_age_sub") }
        static var ageSheetTitle: String { tr("ps_age_sheet_title") }
        static var ageYearsFormat: String { tr("ps_age_years_format") }
        static var yearsUnit: String { tr("ps_years_unit") }
        static var heightTitle: String { tr("ps_height_title") }
        static var heightSub: String { tr("ps_height_sub") }
        static var weightTitle: String { tr("ps_weight_title") }
        static var weightSub: String { tr("ps_weight_sub") }
        static var cmUnit: String { tr("ps_cm") }
        static var kgUnit: String { tr("ps_kg") }
    }

    enum Profile {
        static var title: String { tr("prof_title") }
        static var subtitle: String { tr("prof_subtitle") }
        static var edit: String { tr("prof_edit") }
        static var gender: String { tr("prof_gender") }
        static var age: String { tr("prof_age") }
        static var height: String { tr("prof_height") }
        static var weight: String { tr("prof_weight") }
        static var genderUnspecifiedShort: String { tr("prof_gender_unspecified_short") }
        static var goalsTitle: String { tr("prof_goals_title") }
        static var goalsSubMock: String { tr("prof_goals_sub_mock") }
        static var myWatch: String { tr("prof_my_watch") }
        static var connected: String { tr("prof_connected") }
        static var disconnected: String { tr("prof_disconnected") }
        static var lastSyncMock: String { tr("prof_last_sync_mock") }
        static var menuPersonal: String { tr("prof_menu_personal") }
        static var menuPersonalSub: String { tr("prof_menu_personal_sub") }
        static var menuMetrics: String { tr("prof_menu_metrics") }
        static var menuMetricsSub: String { tr("prof_menu_metrics_sub") }
        static var menuGoals: String { tr("prof_menu_goals") }
        static var menuGoalsSub: String { tr("prof_menu_goals_sub") }
        static var menuSettings: String { tr("prof_menu_settings") }
        static var menuSettingsSub: String { tr("prof_menu_settings_sub") }
        static var menuPrivacy: String { tr("prof_menu_privacy") }
        static var menuPrivacySub: String { tr("prof_menu_privacy_sub") }
        static var menuSupport: String { tr("prof_menu_support") }
        static var menuSupportSub: String { tr("prof_menu_support_sub") }
        static var menuTerms: String { tr("prof_menu_terms") }
        static var menuTermsSub: String { tr("prof_menu_terms_sub") }
        static var menuPolicy: String { tr("prof_menu_policy") }
        static var menuPolicySub: String { tr("prof_menu_policy_sub") }
        static var menuAbout: String { tr("prof_menu_about") }
        static var menuAboutSub: String { tr("prof_menu_about_sub") }
        static var logout: String { tr("prof_logout") }
        static var deleteAccount: String { tr("prof_delete") }
        static var logoutConfirmTitle: String { tr("prof_logout_title") }
        static var logoutConfirmBody: String { tr("prof_logout_body") }
        static var deleteConfirmTitle: String { tr("prof_delete_title") }
        static var deleteConfirmBody: String { tr("prof_delete_body") }
        static var deleteConfirmAction: String { tr("prof_delete_action") }
        static var cancel: String { tr("prof_cancel") }
        static var stubTitle: String { tr("prof_stub_title") }
        static var stubBody: String { tr("prof_stub_body") }
    }

    enum EditProfile {
        static var title: String { tr("edit_title") }
        static var subtitle: String { tr("edit_subtitle") }
        static var photoTitle: String { tr("edit_photo_title") }
        static var photoSub: String { tr("edit_photo_sub") }
        static var photoError: String { tr("edit_photo_error") }
        static var nameLabel: String { tr("edit_name_label") }
        static var save: String { tr("edit_save") }
        static var cancel: String { tr("edit_cancel") }
        static var successTitle: String { tr("edit_success_title") }
        static var successBody: String { tr("edit_success_body") }
        static var successOK: String { tr("edit_success_ok") }
    }

    enum Dashboard {
        static var title: String { tr("dash_title") }
        static var battery: String { tr("dash_battery") }
        static var charge: String { tr("dash_charge") }
        static var device: String { tr("dash_device") }
        static var sdk: String { tr("dash_sdk") }
        static var sdkOk: String { tr("dash_sdk_ok") }
        static var sdkWait: String { tr("dash_sdk_wait") }
        static var liveTraces: String { tr("dash_live_traces") }
        static var liveSub: String { tr("dash_live_sub") }
        static var heartRate: String { tr("dash_hr") }
        static var spo2: String { tr("dash_spo2") }
        static var syncProgress: String { tr("dash_sync") }
        static var syncSub: String { tr("dash_sync_sub") }
        static var progressPct: String { tr("dash_progress_pct") }
        static var deviceCard: String { tr("dash_device_card") }
        static var name: String { tr("dash_name") }
        static var status: String { tr("dash_status") }
        static var actions: String { tr("dash_actions") }
        static var actionsSub: String { tr("dash_actions_sub") }
        static var readBattery: String { tr("dash_read_battery") }
        static var syncTime: String { tr("dash_sync_time") }
        static var readDaily: String { tr("dash_read_daily") }
        static var pipeline: String { tr("dash_pipeline") }
        static var pipelineSub: String { tr("dash_pipeline_sub") }
        static var manualOk: String { tr("dash_manual_ok") }
        static var busy: String { tr("dash_busy") }
        static var capsTitle: String { tr("dash_caps_title") }
        static var capsSub: String { tr("dash_caps_sub") }
        static var capsBody: String { tr("dash_caps_body") }
    }

    enum Scan {
        static var title: String { tr("scan_title") }
        static var bluetooth: String { tr("scan_bluetooth") }
        static var sdk: String { tr("scan_sdk") }
        static var sdkReady: String { tr("scan_sdk_ready") }
        static var sdkInit: String { tr("scan_sdk_init") }
        static var btOn: String { tr("scan_bt_on") }
        static var btOff: String { tr("scan_bt_off") }
        static var connection: String { tr("scan_connection") }
        static var connectionHint: String { tr("scan_connection_hint") }
        static var startScan: String { tr("scan_start") }
        static var stop: String { tr("scan_stop") }
        static var refresh: String { tr("scan_refresh") }
        static var appSettings: String { tr("scan_app_settings") }
        static var xpcHint: String { tr("scan_xpc_hint") }
        static var devices: String { tr("scan_devices") }
        static var noDevices: String { tr("scan_no_devices") }
        static var connect: String { tr("scan_connect") }
        static var disconnect: String { tr("scan_disconnect") }
        static var unknownAddr: String { tr("scan_unknown_addr") }
        static var scanningTitle: String { tr("scan_scanning_title") }
        static var scanningHint: String { tr("scan_scanning_hint") }
    }

    enum Heart {
        static var title: String { tr("heart_title") }
        static var currentLabel: String { tr("heart_current") }
        static var liveChart: String { tr("heart_live_chart") }
        static var bpmTime: String { tr("heart_bpm_time") }
        static var manual: String { tr("heart_manual") }
        static var manualSub: String { tr("heart_manual_sub") }
    }

    enum Oxygen {
        static var title: String { tr("oxygen_title") }
        static var liveChart: String { tr("oxygen_live_chart") }
        static var o2Title: String { tr("oxygen_chart_title") }
        static var manual: String { tr("oxygen_manual") }
        static var manualSub: String { tr("oxygen_manual_sub") }
    }

    enum Temp {
        static var title: String { tr("temp_title") }
        static var body: String { tr("temp_body") }
        static var skin: String { tr("temp_skin") }
        static var trend: String { tr("temp_trend") }
        static func trendSub(progress: Int) -> String {
            // Avoid `String(format:)` type mismatches if a locale string ever uses the wrong specifier (e.g. `%.1f` with Int).
            var s = tr("temp_trend_sub_fmt")
            s = s.replacingOccurrences(of: "%d", with: "\(progress)")
            s = s.replacingOccurrences(of: "%%", with: "%")
            return s
        }
        static var celsius: String { tr("temp_c") }
        static var manual: String { tr("temp_manual") }
        static var manualSub: String { tr("temp_manual_sub") }
        static var notSupported: String { tr("temp_not_supported") }
        static var notSupportedSub: String { tr("temp_not_supported_sub") }
    }

    enum ECG {
        static var title: String { tr("ecg_title") }
        static var supported: String { tr("ecg_supported") }
        static var supportedSub: String { tr("ecg_supported_sub") }
        static var notAvail: String { tr("ecg_not_avail") }
        static var notAvailSub: String { tr("ecg_not_avail_sub") }
        static var progress: String { tr("ecg_progress") }
        static var samples: String { tr("ecg_samples") }
        static var curve: String { tr("ecg_curve") }
        static var progressPct: String { tr("ecg_progress_pct") }
        static var controls: String { tr("ecg_controls") }
        static var controlsSub: String { tr("ecg_controls_sub") }
        static var start: String { tr("ecg_start") }
        static var waveTitle: String { tr("ecg_wave_title") }
        static var waveSubIdle: String { tr("ecg_wave_sub_idle") }
        static var waveSubLive: String { tr("ecg_wave_sub_live") }
        static var waveFrozen: String { tr("ecg_wave_frozen") }
        static var waveWaiting: String { tr("ecg_wave_waiting") }
    }

    enum Micro {
        static var title: String { tr("micro_title") }
        static var check: String { tr("micro_check") }
        static var checkOkSub: String { tr("micro_check_ok") }
        static var checkNoSub: String { tr("micro_check_no") }
        static var progressLabel: String { tr("micro_progress") }
        static var chart: String { tr("micro_chart") }
        static var chartSub: String { tr("micro_chart_sub") }
        static var completion: String { tr("micro_completion") }
        static var run: String { tr("micro_run") }
        static var runSub: String { tr("micro_run_sub") }
        static var last: String { tr("micro_last") }
        static var lastSubNone: String { tr("micro_last_none") }
        static var lastSubOk: String { tr("micro_last_ok") }
        static var metricStress: String { tr("micro_metric_stress") }
        static var metricTemp: String { tr("micro_metric_temp") }
        static var unitMmHg: String { tr("micro_unit_mmhg") }
    }

    enum Settings {
        static var title: String { tr("settings_title") }
        static var profile: String { tr("settings_profile") }
        static var profileSub: String { tr("settings_profile_sub") }
        static var height: String { tr("settings_height") }
        static var weight: String { tr("settings_weight") }
        static var age: String { tr("settings_age") }
        static var sex: String { tr("settings_sex") }
        static var female: String { tr("settings_female") }
        static var male: String { tr("settings_male") }
        static var targetSteps: String { tr("settings_steps") }
        static var syncPersonal: String { tr("settings_sync_personal") }
        static var devicePrefs: String { tr("settings_device_prefs") }
        static var devicePrefsSub: String { tr("settings_device_prefs_sub") }
        static var metric: String { tr("settings_metric") }
        static var time24: String { tr("settings_24h") }
        static var autoHr: String { tr("settings_auto_hr") }
        static var autoHrHint: String { tr("settings_auto_hr_hint") }
        static var autoTemp: String { tr("settings_auto_temp") }
        static var applyToggles: String { tr("settings_apply") }
        static var timeCard: String { tr("settings_time_card") }
        static var timeCardSub: String { tr("settings_time_sub") }
        static var syncTimeBand: String { tr("settings_sync_time_band") }
    }

    enum State {
        static var idle: String { tr("state_idle") }
        static var starting: String { tr("state_starting") }
        static var measuring: String { tr("state_measuring") }
        static var notWorn: String { tr("state_not_worn") }
        static var deviceBusy: String { tr("state_device_busy") }
        static var finished: String { tr("state_finished") }
        static var done: String { tr("state_done") }
        static var unsupported: String { tr("state_unsupported") }
        static var calibrating: String { tr("state_calibrating") }
        static var calibDone: String { tr("state_calib_done") }
        static var invalid: String { tr("state_invalid") }
        static var preparing: String { tr("state_preparing") }
        static var recording: String { tr("state_recording") }
        static var leadOff: String { tr("state_lead_off") }
        static var busy: String { tr("state_busy") }
        static var stopped: String { tr("state_stopped") }
        static var failed: String { tr("state_failed") }
        static var complete: String { tr("state_complete") }
        static var noFunc: String { tr("state_no_func") }
    }

    enum Chart {
        static var emptyHint: String { tr("chart_empty_hint") }
    }

    enum Err {
        static var veepooUnavailable: String { tr("err_veepoo_unavailable") }
        static var deviceNotConnected: String { tr("err_not_connected") }
        static var dailyBusy: String { tr("err_daily_busy") }
        static var opBusy: String { tr("err_op_busy") }
        static var ecgUnsupported: String { tr("err_ecg_unsupported") }
        static var tempUnsupported: String { tr("err_temp_unsupported") }
        static var microUnsupported: String { tr("err_micro_unsupported") }
        static var syncTime: String { tr("err_sync_time") }
        static var syncPersonal: String { tr("err_sync_personal") }
        static var settingFailed: String { tr("err_setting_failed") }
        static var settingMap: String { tr("err_setting_map") }
        static var settingState: String { tr("err_setting_state") }
        static var readBattery: String { tr("err_read_battery") }
        static var btPermission: String { tr("err_bt_permission") }
        static var btPermissionDetail: String { tr("err_bt_permission_detail") }
        static var btOff: String { tr("err_bt_off") }
        static var btUnsupported: String { tr("err_bt_unsupported") }
        static var btScan: String { tr("err_bt_scan") }
        static var measurementTimeout: String { tr("err_measurement_timeout") }
    }

    enum ConnBar {
        static var noDevice: String { tr("conn_bar_no_device") }
        static var sdkInit: String { tr("conn_bar_sdk_init") }
        static var btOff: String { tr("conn_bar_bt_off") }
        static var notLinked: String { tr("conn_bar_not_linked") }
        static var phoneBtOn: String { tr("conn_bar_phone_bt_on") }
        static var phoneBtOff: String { tr("conn_bar_phone_bt_off") }
        static var btWarming: String { tr("conn_bar_bt_warming") }
    }

    enum Measure {
        static func title(_ kind: MeasurementKind) -> String {
            String(localized: String.LocalizationValue(kind.titleKey))
        }

        static var hint: String { tr("measure_hint") }
        static var close: String { tr("measure_close") }
    }

    enum Vitals {
        static var title: String { tr("vitals_title") }
        static var bpCard: String { tr("vitals_bp_card") }
        static var bpSub: String { tr("vitals_bp_sub") }
        static var glucoseCard: String { tr("vitals_glucose_card") }
        static var glucoseSub: String { tr("vitals_glucose_sub") }
        static var lastReading: String { tr("vitals_last") }
        static var mmol: String { tr("vitals_mmol") }
    }

    enum Hub {
        static var section: String { tr("hub_section") }
        static var sectionSub: String { tr("hub_section_sub") }
        static var steps: String { tr("hub_steps") }
        static var sleep: String { tr("hub_sleep") }
        static var sleepSub: String { tr("hub_sleep_sub") }
        static var vitals: String { tr("hub_vitals") }
        static var vitalsSub: String { tr("hub_vitals_sub") }
    }

    enum Conn {
        static var disconnected: String { tr("conn_disconnected") }
        static var connecting: String { tr("conn_connecting") }
        static var connected: String { tr("conn_connected") }
        static var verified: String { tr("conn_verified") }
        static var failed: String { tr("conn_failed") }
        static var timeout: String { tr("conn_timeout") }
    }

    enum Op {
        static var idle: String { tr("op_idle") }
        static var readingDaily: String { tr("op_reading_daily") }
        static var heart: String { tr("op_heart") }
        static var oxygen: String { tr("op_oxygen") }
        static var temperature: String { tr("op_temperature") }
        static var ecg: String { tr("op_ecg") }
        static var micro: String { tr("op_micro") }
        static var bloodPressure: String { tr("op_bp") }
        static var bloodGlucose: String { tr("op_glucose") }
        static var readingSteps: String { tr("op_steps") }
        static var readingSleep: String { tr("op_sleep") }
    }

    static var btnStart: String { tr("btn_start") }
    static var btnStop: String { tr("btn_stop") }

    enum Battery {
        static var charging: String { tr("bat_charging") }
        static var full: String { tr("bat_full") }
        static var normal: String { tr("bat_normal") }
    }
}

/// Non-observable access to the active language bundle (set by `LanguageStore`).
enum LanguageStoreBootstrap {
    nonisolated(unsafe) static var bundle: Bundle = .main
}
