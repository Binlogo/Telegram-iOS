import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

enum SelectivePrivacySettingsKind {
    case presence
    case groupInvitations
    case voiceCalls
    case profilePhoto
    case forwards
    case phoneNumber
}

private enum SelectivePrivacySettingType {
    case everybody
    case contacts
    case nobody
    
    init(_ setting: SelectivePrivacySettings) {
        switch setting {
            case .disableEveryone:
                self = .nobody
            case .enableContacts:
                self = .contacts
            case .enableEveryone:
                self = .everybody
        }
    }
}

enum SelectivePrivacySettingsPeerTarget {
    case main
    case callP2P
}

private final class SelectivePrivacySettingsControllerArguments {
    let context: AccountContext
    
    let updateType: (SelectivePrivacySettingType) -> Void
    let openSelective: (SelectivePrivacySettingsPeerTarget, Bool) -> Void
    
    let updateCallP2PMode: ((SelectivePrivacySettingType) -> Void)?
    let updateCallIntegrationEnabled: ((Bool) -> Void)?
    
    init(context: AccountContext, updateType: @escaping (SelectivePrivacySettingType) -> Void, openSelective: @escaping (SelectivePrivacySettingsPeerTarget, Bool) -> Void, updateCallP2PMode: ((SelectivePrivacySettingType) -> Void)?, updateCallIntegrationEnabled: ((Bool) -> Void)?) {
        self.context = context
        self.updateType = updateType
        self.openSelective = openSelective
        
        self.updateCallP2PMode = updateCallP2PMode
        self.updateCallIntegrationEnabled = updateCallIntegrationEnabled
    }
}

private enum SelectivePrivacySettingsSection: Int32 {
    case forwards
    case setting
    case peers
    case callsP2P
    case callsP2PPeers
    case callsIntegrationEnabled
}

private func stringForUserCount(_ peers: [PeerId: SelectivePrivacyPeer], strings: PresentationStrings) -> String {
    if peers.isEmpty {
        return strings.PrivacyLastSeenSettings_EmpryUsersPlaceholder
    } else {
        var result = 0
        for (_, peer) in peers {
            result += peer.userCount
        }
        return strings.UserCount(Int32(result))
    }
}

private enum SelectivePrivacySettingsEntry: ItemListNodeEntry {
    case forwardsPreviewHeader(PresentationTheme, String)
    case forwardsPreview(PresentationTheme, TelegramWallpaper, PresentationFontSize, PresentationStrings, PresentationDateTimeFormat, PresentationPersonNameOrder, String, Bool, String)
    case settingHeader(PresentationTheme, String)
    case everybody(PresentationTheme, String, Bool)
    case contacts(PresentationTheme, String, Bool)
    case nobody(PresentationTheme, String, Bool)
    case settingInfo(PresentationTheme, String)
    case exceptionsHeader(PresentationTheme, String)
    case disableFor(PresentationTheme, String, String)
    case enableFor(PresentationTheme, String, String)
    case peersInfo(PresentationTheme, String)
    case callsP2PHeader(PresentationTheme, String)
    case callsP2PAlways(PresentationTheme, String, Bool)
    case callsP2PContacts(PresentationTheme, String, Bool)
    case callsP2PNever(PresentationTheme, String, Bool)
    case callsP2PInfo(PresentationTheme, String)
    case callsP2PDisableFor(PresentationTheme, String, String)
    case callsP2PEnableFor(PresentationTheme, String, String)
    case callsP2PPeersInfo(PresentationTheme, String)
    case callsIntegrationEnabled(PresentationTheme, String, Bool)
    case callsIntegrationInfo(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
            case .forwardsPreviewHeader, .forwardsPreview:
                return SelectivePrivacySettingsSection.forwards.rawValue
            case .settingHeader, .everybody, .contacts, .nobody, .settingInfo:
                return SelectivePrivacySettingsSection.setting.rawValue
            case .exceptionsHeader, .disableFor, .enableFor, .peersInfo:
                return SelectivePrivacySettingsSection.peers.rawValue
            case .callsP2PHeader, .callsP2PAlways, .callsP2PContacts, .callsP2PNever, .callsP2PInfo:
                return SelectivePrivacySettingsSection.callsP2P.rawValue
            case .callsP2PDisableFor, .callsP2PEnableFor, .callsP2PPeersInfo:
                return SelectivePrivacySettingsSection.callsP2PPeers.rawValue
            case .callsIntegrationEnabled, .callsIntegrationInfo:
                return SelectivePrivacySettingsSection.callsIntegrationEnabled.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
            case .forwardsPreviewHeader:
                return 0
            case .forwardsPreview:
                return 1
            case .settingHeader:
                return 2
            case .everybody:
                return 3
            case .contacts:
                return 4
            case .nobody:
                return 5
            case .settingInfo:
                return 6
            case .exceptionsHeader:
                return 7
            case .disableFor:
                return 8
            case .enableFor:
                return 9
            case .peersInfo:
                return 10
            case .callsP2PHeader:
                return 11
            case .callsP2PAlways:
                return 12
            case .callsP2PContacts:
                return 13
            case .callsP2PNever:
                return 14
            case .callsP2PInfo:
                return 15
            case .callsP2PDisableFor:
                return 16
            case .callsP2PEnableFor:
                return 17
            case .callsP2PPeersInfo:
                return 18
            case .callsIntegrationEnabled:
                return 19
            case .callsIntegrationInfo:
                return 20
        }
    }
    
    static func ==(lhs: SelectivePrivacySettingsEntry, rhs: SelectivePrivacySettingsEntry) -> Bool {
        switch lhs {
            case let .forwardsPreviewHeader(lhsTheme, lhsText):
                if case let .forwardsPreviewHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .forwardsPreview(lhsTheme, lhsWallpaper, lhsFontSize, lhsStrings, lhsTimeFormat, lhsNameOrder, lhsPeerName, lhsLinkEnabled, lhsTooltipText):
                if case let .forwardsPreview(rhsTheme, rhsWallpaper, rhsFontSize, rhsStrings, rhsTimeFormat, rhsNameOrder, rhsPeerName, rhsLinkEnabled, rhsTooltipText) = rhs, lhsTheme === rhsTheme, lhsWallpaper == rhsWallpaper, lhsFontSize == rhsFontSize, lhsStrings === rhsStrings, lhsTimeFormat == rhsTimeFormat, lhsNameOrder == rhsNameOrder, lhsPeerName == rhsPeerName, lhsLinkEnabled == rhsLinkEnabled, lhsTooltipText == rhsTooltipText {
                    return true
                } else {
                    return false
                }
            case let .settingHeader(lhsTheme, lhsText):
                if case let .settingHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .everybody(lhsTheme, lhsText, lhsValue):
                if case let .everybody(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .contacts(lhsTheme, lhsText, lhsValue):
                if case let .contacts(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .nobody(lhsTheme, lhsText, lhsValue):
                if case let nobody(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .exceptionsHeader(lhsTheme, lhsText):
                if case let .exceptionsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .settingInfo(lhsTheme, lhsText):
                if case let .settingInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .disableFor(lhsTheme, lhsText, lhsValue):
                if case let .disableFor(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .enableFor(lhsTheme, lhsText, lhsValue):
                if case let .enableFor(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .peersInfo(lhsTheme, lhsText):
                if case let .peersInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .callsP2PHeader(lhsTheme, lhsText):
                if case let .callsP2PHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .callsP2PInfo(lhsTheme, lhsText):
                if case let .callsP2PInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .callsP2PAlways(lhsTheme, lhsText, lhsValue):
                if case let .callsP2PAlways(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .callsP2PContacts(lhsTheme, lhsText, lhsValue):
                if case let .callsP2PContacts(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .callsP2PNever(lhsTheme, lhsText, lhsValue):
                if case let .callsP2PNever(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .callsP2PDisableFor(lhsTheme, lhsText, lhsValue):
                if case let .callsP2PDisableFor(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .callsP2PEnableFor(lhsTheme, lhsText, lhsValue):
                if case let .callsP2PEnableFor(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .callsP2PPeersInfo(lhsTheme, lhsText):
                if case let .callsP2PPeersInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .callsIntegrationEnabled(lhsTheme, lhsText, lhsValue):
                if case let .callsIntegrationEnabled(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .callsIntegrationInfo(lhsTheme, lhsText):
                if case let .callsIntegrationInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: SelectivePrivacySettingsEntry, rhs: SelectivePrivacySettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: SelectivePrivacySettingsControllerArguments) -> ListViewItem {
        switch self {
            case let .forwardsPreviewHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, multiline: true, sectionId: self.section)
            case let .forwardsPreview(theme, wallpaper, fontSize, strings, dateTimeFormat, nameDisplayOrder, peerName, linkEnabled, tooltipText):
                return ForwardPrivacyChatPreviewItem(context: arguments.context, theme: theme, strings: strings, sectionId: self.section, fontSize: fontSize, wallpaper: wallpaper, dateTimeFormat: dateTimeFormat, nameDisplayOrder: nameDisplayOrder, peerName: peerName, linkEnabled: linkEnabled, tooltipText: tooltipText)
            case let .settingHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, multiline: true, sectionId: self.section)
            case let .everybody(theme, text, value):
                return ItemListCheckboxItem(theme: theme, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.updateType(.everybody)
                })
            case let .contacts(theme, text, value):
                return ItemListCheckboxItem(theme: theme, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.updateType(.contacts)
                })
            case let .nobody(theme, text, value):
                return ItemListCheckboxItem(theme: theme, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.updateType(.nobody)
                })
            case let .settingInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .exceptionsHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .disableFor(theme, title, value):
                return ItemListDisclosureItem(theme: theme, title: title, label: value, sectionId: self.section, style: .blocks, action: {
                    arguments.openSelective(.main, false)
                })
            case let .enableFor(theme, title, value):
                return ItemListDisclosureItem(theme: theme, title: title, label: value, sectionId: self.section, style: .blocks, action: {
                    arguments.openSelective(.main, true)
                })
            case let .peersInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .callsP2PHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .callsP2PAlways(theme, text, value):
                return ItemListCheckboxItem(theme: theme, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.updateCallP2PMode?(.everybody)
                })
            case let .callsP2PContacts(theme, text, value):
                return ItemListCheckboxItem(theme: theme, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.updateCallP2PMode?(.contacts)
                })
            case let .callsP2PNever(theme, text, value):
                return ItemListCheckboxItem(theme: theme, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.updateCallP2PMode?(.nobody)
                })
            case let .callsP2PInfo(theme, text):
                    return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .callsP2PDisableFor(theme, title, value):
                return ItemListDisclosureItem(theme: theme, title: title, label: value, sectionId: self.section, style: .blocks, action: {
                    arguments.openSelective(.callP2P, false)
                })
            case let .callsP2PEnableFor(theme, title, value):
                return ItemListDisclosureItem(theme: theme, title: title, label: value, sectionId: self.section, style: .blocks, action: {
                    arguments.openSelective(.callP2P, true)
                })
            case let .callsP2PPeersInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .callsIntegrationEnabled(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.updateCallIntegrationEnabled?(value)
                })
            case let .callsIntegrationInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
        }
    }
}

private struct SelectivePrivacySettingsControllerState: Equatable {
    let setting: SelectivePrivacySettingType
    let enableFor: [PeerId: SelectivePrivacyPeer]
    let disableFor: [PeerId: SelectivePrivacyPeer]
    
    let saving: Bool
    
    let callDataSaving: VoiceCallDataSaving?
    let callP2PMode: SelectivePrivacySettingType?
    let callP2PEnableFor: [PeerId: SelectivePrivacyPeer]?
    let callP2PDisableFor: [PeerId: SelectivePrivacyPeer]?
    let callIntegrationAvailable: Bool?
    let callIntegrationEnabled: Bool?
    
    init(setting: SelectivePrivacySettingType, enableFor: [PeerId: SelectivePrivacyPeer], disableFor: [PeerId: SelectivePrivacyPeer], saving: Bool, callDataSaving: VoiceCallDataSaving?, callP2PMode: SelectivePrivacySettingType?, callP2PEnableFor: [PeerId: SelectivePrivacyPeer]?, callP2PDisableFor: [PeerId: SelectivePrivacyPeer]?, callIntegrationAvailable: Bool?, callIntegrationEnabled: Bool?) {
        self.setting = setting
        self.enableFor = enableFor
        self.disableFor = disableFor
        self.saving = saving
        self.callDataSaving = callDataSaving
        self.callP2PMode = callP2PMode
        self.callP2PEnableFor = callP2PEnableFor
        self.callP2PDisableFor = callP2PDisableFor
        self.callIntegrationAvailable = callIntegrationAvailable
        self.callIntegrationEnabled = callIntegrationEnabled
    }
    
    static func ==(lhs: SelectivePrivacySettingsControllerState, rhs: SelectivePrivacySettingsControllerState) -> Bool {
        if lhs.setting != rhs.setting {
            return false
        }
        if lhs.enableFor != rhs.enableFor {
            return false
        }
        if lhs.disableFor != rhs.disableFor {
            return false
        }
        if lhs.saving != rhs.saving {
            return false
        }
        if lhs.callDataSaving != rhs.callDataSaving {
            return false
        }
        if lhs.callP2PMode != rhs.callP2PMode {
            return false
        }
        if lhs.callP2PEnableFor != rhs.callP2PEnableFor {
            return false
        }
        if lhs.callP2PDisableFor != rhs.callP2PDisableFor {
            return false
        }
        if lhs.callIntegrationAvailable != rhs.callIntegrationAvailable {
            return false
        }
        if lhs.callIntegrationEnabled != rhs.callIntegrationEnabled {
            return false
        }
        
        return true
    }
    
    func withUpdatedSetting(_ setting: SelectivePrivacySettingType) -> SelectivePrivacySettingsControllerState {
        return SelectivePrivacySettingsControllerState(setting: setting, enableFor: self.enableFor, disableFor: self.disableFor, saving: self.saving, callDataSaving: self.callDataSaving, callP2PMode: self.callP2PMode, callP2PEnableFor: self.callP2PEnableFor, callP2PDisableFor: self.callP2PDisableFor, callIntegrationAvailable: self.callIntegrationAvailable, callIntegrationEnabled: self.callIntegrationEnabled)
    }
    
    func withUpdatedEnableFor(_ enableFor: [PeerId: SelectivePrivacyPeer]) -> SelectivePrivacySettingsControllerState {
        return SelectivePrivacySettingsControllerState(setting: self.setting, enableFor: enableFor, disableFor: self.disableFor, saving: self.saving, callDataSaving: self.callDataSaving, callP2PMode: self.callP2PMode, callP2PEnableFor: self.callP2PEnableFor, callP2PDisableFor: self.callP2PDisableFor, callIntegrationAvailable: self.callIntegrationAvailable, callIntegrationEnabled: self.callIntegrationEnabled)
    }
    
    func withUpdatedDisableFor(_ disableFor: [PeerId: SelectivePrivacyPeer]) -> SelectivePrivacySettingsControllerState {
        return SelectivePrivacySettingsControllerState(setting: self.setting, enableFor: self.enableFor, disableFor: disableFor, saving: self.saving, callDataSaving: self.callDataSaving, callP2PMode: self.callP2PMode, callP2PEnableFor: self.callP2PEnableFor, callP2PDisableFor: self.callP2PDisableFor, callIntegrationAvailable: self.callIntegrationAvailable, callIntegrationEnabled: self.callIntegrationEnabled)
    }
    
    func withUpdatedSaving(_ saving: Bool) -> SelectivePrivacySettingsControllerState {
        return SelectivePrivacySettingsControllerState(setting: self.setting, enableFor: self.enableFor, disableFor: self.disableFor, saving: saving, callDataSaving: self.callDataSaving, callP2PMode: self.callP2PMode, callP2PEnableFor: self.callP2PEnableFor, callP2PDisableFor: self.callP2PDisableFor, callIntegrationAvailable: self.callIntegrationAvailable, callIntegrationEnabled: self.callIntegrationEnabled)
    }
    
    func withUpdatedCallP2PMode(_ mode: SelectivePrivacySettingType) -> SelectivePrivacySettingsControllerState {
        return SelectivePrivacySettingsControllerState(setting: self.setting, enableFor: self.enableFor, disableFor: self.disableFor, saving: self.saving, callDataSaving: self.callDataSaving, callP2PMode: mode, callP2PEnableFor: self.callP2PEnableFor, callP2PDisableFor: self.callP2PDisableFor, callIntegrationAvailable: self.callIntegrationAvailable, callIntegrationEnabled: self.callIntegrationEnabled)
    }
    
    func withUpdatedCallP2PEnableFor(_ enableFor: [PeerId: SelectivePrivacyPeer]) -> SelectivePrivacySettingsControllerState {
        return SelectivePrivacySettingsControllerState(setting: self.setting, enableFor: self.enableFor, disableFor: self.disableFor, saving: self.saving, callDataSaving: self.callDataSaving, callP2PMode: self.callP2PMode, callP2PEnableFor: enableFor, callP2PDisableFor: self.callP2PDisableFor, callIntegrationAvailable: self.callIntegrationAvailable, callIntegrationEnabled: self.callIntegrationEnabled)
    }
    
    func withUpdatedCallP2PDisableFor(_ disableFor: [PeerId: SelectivePrivacyPeer]) -> SelectivePrivacySettingsControllerState {
        return SelectivePrivacySettingsControllerState(setting: self.setting, enableFor: self.enableFor, disableFor: self.disableFor, saving: self.saving, callDataSaving: self.callDataSaving, callP2PMode: self.callP2PMode, callP2PEnableFor: self.callP2PEnableFor, callP2PDisableFor: disableFor, callIntegrationAvailable: self.callIntegrationAvailable, callIntegrationEnabled: self.callIntegrationEnabled)
    }
    
    func withUpdatedCallsIntegrationEnabled(_ enabled: Bool) -> SelectivePrivacySettingsControllerState {
        return SelectivePrivacySettingsControllerState(setting: self.setting, enableFor: self.enableFor, disableFor: self.disableFor, saving: self.saving, callDataSaving: self.callDataSaving, callP2PMode: self.callP2PMode, callP2PEnableFor: self.callP2PEnableFor, callP2PDisableFor: self.callP2PDisableFor, callIntegrationAvailable: self.callIntegrationAvailable, callIntegrationEnabled: enabled)
    }
}

private func selectivePrivacySettingsControllerEntries(presentationData: PresentationData, kind: SelectivePrivacySettingsKind, state: SelectivePrivacySettingsControllerState, peerName: String) -> [SelectivePrivacySettingsEntry] {
    var entries: [SelectivePrivacySettingsEntry] = []
    
    let settingTitle: String
    let settingInfoText: String
    let disableForText: String
    let enableForText: String
    switch kind {
        case .presence:
            settingTitle = presentationData.strings.PrivacyLastSeenSettings_WhoCanSeeMyTimestamp
            settingInfoText = presentationData.strings.PrivacyLastSeenSettings_CustomHelp
            disableForText = presentationData.strings.PrivacyLastSeenSettings_NeverShareWith
            enableForText = presentationData.strings.PrivacyLastSeenSettings_AlwaysShareWith
        case .groupInvitations:
            settingTitle = presentationData.strings.Privacy_GroupsAndChannels_WhoCanAddMe
            settingInfoText = presentationData.strings.Privacy_GroupsAndChannels_CustomHelp
            disableForText = presentationData.strings.Privacy_GroupsAndChannels_NeverAllow
            enableForText = presentationData.strings.Privacy_GroupsAndChannels_AlwaysAllow
        case .voiceCalls:
            settingTitle = presentationData.strings.Privacy_Calls_WhoCanCallMe
            settingInfoText = presentationData.strings.Privacy_Calls_CustomHelp
            disableForText = presentationData.strings.Privacy_GroupsAndChannels_NeverAllow
            enableForText = presentationData.strings.Privacy_GroupsAndChannels_AlwaysAllow
        case .profilePhoto:
            settingTitle = presentationData.strings.Privacy_ProfilePhoto_WhoCanSeeMyPhoto
            settingInfoText = presentationData.strings.Privacy_ProfilePhoto_CustomHelp
            disableForText = presentationData.strings.PrivacyLastSeenSettings_NeverShareWith
            enableForText = presentationData.strings.PrivacyLastSeenSettings_AlwaysShareWith
        case .forwards:
            settingTitle = presentationData.strings.Privacy_Forwards_WhoCanForward
            settingInfoText = presentationData.strings.Privacy_Forwards_CustomHelp
            disableForText = presentationData.strings.Privacy_GroupsAndChannels_NeverAllow
            enableForText = presentationData.strings.Privacy_GroupsAndChannels_AlwaysAllow
        case .phoneNumber:
            settingTitle = presentationData.strings.PrivacyPhoneNumberSettings_WhoCanSeeMyPhoneNumber
            settingInfoText = presentationData.strings.PrivacyPhoneNumberSettings_CustomHelp
            disableForText = presentationData.strings.PrivacyLastSeenSettings_NeverShareWith
            enableForText = presentationData.strings.PrivacyLastSeenSettings_AlwaysShareWith
    }
    
    if case .forwards = kind {
        let linkEnabled: Bool
        let tootipText: String
        switch state.setting {
            case .everybody:
                tootipText = presentationData.strings.Privacy_Forwards_AlwaysLink
                linkEnabled = true
            case .contacts:
                tootipText = presentationData.strings.Privacy_Forwards_LinkIfAllowed
                linkEnabled = true
            case .nobody:
                tootipText = presentationData.strings.Privacy_Forwards_NeverLink
                linkEnabled = false
        }
        entries.append(.forwardsPreviewHeader(presentationData.theme, presentationData.strings.Privacy_Forwards_Preview))
        entries.append(.forwardsPreview(presentationData.theme, presentationData.chatWallpaper, presentationData.fontSize, presentationData.strings, presentationData.dateTimeFormat, presentationData.nameDisplayOrder, peerName, linkEnabled, tootipText))
    }
    
    entries.append(.settingHeader(presentationData.theme, settingTitle))
    
    entries.append(.everybody(presentationData.theme, presentationData.strings.PrivacySettings_LastSeenEverybody, state.setting == .everybody))
    entries.append(.contacts(presentationData.theme, presentationData.strings.PrivacySettings_LastSeenContacts, state.setting == .contacts))
    switch kind {
        case .presence, .voiceCalls, .forwards, .phoneNumber:
            entries.append(.nobody(presentationData.theme, presentationData.strings.PrivacySettings_LastSeenNobody, state.setting == .nobody))
        case .groupInvitations, .profilePhoto:
            break
    }
    entries.append(.settingInfo(presentationData.theme, settingInfoText))
    
    entries.append(.exceptionsHeader(presentationData.theme, presentationData.strings.GroupInfo_Permissions_Exceptions))
    
    switch state.setting {
        case .everybody:
            entries.append(.disableFor(presentationData.theme, disableForText, stringForUserCount(state.disableFor, strings: presentationData.strings)))
        case .contacts:
            entries.append(.disableFor(presentationData.theme, disableForText, stringForUserCount(state.disableFor, strings: presentationData.strings)))
            entries.append(.enableFor(presentationData.theme, enableForText, stringForUserCount(state.enableFor, strings: presentationData.strings)))
        case .nobody:
            entries.append(.enableFor(presentationData.theme, enableForText, stringForUserCount(state.enableFor, strings: presentationData.strings)))
    }
    entries.append(.peersInfo(presentationData.theme, presentationData.strings.PrivacyLastSeenSettings_CustomShareSettingsHelp))
    
    if case .voiceCalls = kind, let p2pMode = state.callP2PMode, let integrationAvailable = state.callIntegrationAvailable, let integrationEnabled = state.callIntegrationEnabled  {
        entries.append(.callsP2PHeader(presentationData.theme, presentationData.strings.Privacy_Calls_P2P.uppercased()))
        
        entries.append(.callsP2PAlways(presentationData.theme, presentationData.strings.Privacy_Calls_P2PAlways, p2pMode == .everybody))
        entries.append(.callsP2PContacts(presentationData.theme, presentationData.strings.Privacy_Calls_P2PContacts, p2pMode == .contacts))
        entries.append(.callsP2PNever(presentationData.theme, presentationData.strings.Privacy_Calls_P2PNever, p2pMode == .nobody))
        entries.append(.callsP2PInfo(presentationData.theme, presentationData.strings.Privacy_Calls_P2PHelp))
        
        if let callP2PMode = state.callP2PMode, let disableFor = state.callP2PDisableFor, let enableFor = state.callP2PEnableFor {
            switch callP2PMode {
                case .everybody:
                    entries.append(.callsP2PDisableFor(presentationData.theme, disableForText, stringForUserCount(disableFor, strings: presentationData.strings)))
                case .contacts:
                    entries.append(.callsP2PDisableFor(presentationData.theme, disableForText, stringForUserCount(disableFor, strings: presentationData.strings)))
                    entries.append(.callsP2PEnableFor(presentationData.theme, enableForText, stringForUserCount(enableFor, strings: presentationData.strings)))
                case .nobody:
                    entries.append(.callsP2PEnableFor(presentationData.theme, enableForText, stringForUserCount(enableFor, strings: presentationData.strings)))
            }
        }
        entries.append(.callsP2PPeersInfo(presentationData.theme, presentationData.strings.PrivacyLastSeenSettings_CustomShareSettingsHelp))
        
        if integrationAvailable {
            entries.append(.callsIntegrationEnabled(presentationData.theme, presentationData.strings.Privacy_Calls_Integration, integrationEnabled))
            entries.append(.callsIntegrationInfo(presentationData.theme, presentationData.strings.Privacy_Calls_IntegrationHelp))
        }
    }
    
    return entries
}

func selectivePrivacySettingsController(context: AccountContext, kind: SelectivePrivacySettingsKind, current: SelectivePrivacySettings, callSettings: (SelectivePrivacySettings, VoiceCallSettings)? = nil, voipConfiguration: VoipConfiguration? = nil, callIntegrationAvailable: Bool? = nil, updated: @escaping (SelectivePrivacySettings, (SelectivePrivacySettings, VoiceCallSettings)?) -> Void) -> ViewController {
    let strings = context.sharedContext.currentPresentationData.with { $0 }.strings
    
    var initialEnableFor: [PeerId: SelectivePrivacyPeer] = [:]
    var initialDisableFor: [PeerId: SelectivePrivacyPeer] = [:]
    switch current {
        case let .disableEveryone(enableFor):
            initialEnableFor = enableFor
        case let .enableContacts(enableFor, disableFor):
            initialEnableFor = enableFor
            initialDisableFor = disableFor
        case let .enableEveryone(disableFor):
            initialDisableFor = disableFor
    }
    var initialCallP2PEnableFor: [PeerId: SelectivePrivacyPeer]?
    var initialCallP2PDisableFor: [PeerId: SelectivePrivacyPeer]?
    if let callCurrent = callSettings?.0 {
        switch callCurrent {
            case let .disableEveryone(enableFor):
                initialCallP2PEnableFor = enableFor
                initialCallP2PDisableFor = [:]
            case let .enableContacts(enableFor, disableFor):
                initialCallP2PEnableFor = enableFor
                initialCallP2PDisableFor = disableFor
            case let .enableEveryone(disableFor):
                initialCallP2PEnableFor = [:]
                initialCallP2PDisableFor = disableFor
        }
    }
    
    let initialState = SelectivePrivacySettingsControllerState(setting: SelectivePrivacySettingType(current), enableFor: initialEnableFor, disableFor: initialDisableFor, saving: false, callDataSaving: callSettings?.1.dataSaving, callP2PMode: callSettings != nil ? SelectivePrivacySettingType(callSettings!.0) : nil, callP2PEnableFor: initialCallP2PEnableFor, callP2PDisableFor: initialCallP2PDisableFor, callIntegrationAvailable: callIntegrationAvailable, callIntegrationEnabled: callSettings?.1.enableSystemIntegration)
    
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((SelectivePrivacySettingsControllerState) -> SelectivePrivacySettingsControllerState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    var dismissImpl: (() -> Void)?
    var pushControllerImpl: ((ViewController, Bool) -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    
    let actionsDisposable = DisposableSet()
    let updateSettingsDisposable = MetaDisposable()
    
    let addPeerDisposable = MetaDisposable()
    actionsDisposable.add(addPeerDisposable)
    
    let arguments = SelectivePrivacySettingsControllerArguments(context: context, updateType: { type in
        updateState {
            $0.withUpdatedSetting(type)
        }
    }, openSelective: { target, enable in
        let title: String
        if enable {
            switch kind {
                case .presence:
                    title = strings.PrivacyLastSeenSettings_AlwaysShareWith_Title
                case .groupInvitations:
                    title = strings.Privacy_GroupsAndChannels_AlwaysAllow_Title
                case .voiceCalls:
                    title = strings.Privacy_Calls_AlwaysAllow_Title
                case .profilePhoto:
                    title = strings.Privacy_ProfilePhoto_AlwaysShareWith_Title
                case .forwards:
                    title = strings.Privacy_Forwards_AlwaysAllow_Title
                case .phoneNumber:
                    title = strings.PrivacyLastSeenSettings_AlwaysShareWith_Title
            }
        } else {
            switch kind {
                case .presence:
                    title = strings.PrivacyLastSeenSettings_NeverShareWith_Title
                case .groupInvitations:
                    title = strings.Privacy_GroupsAndChannels_NeverAllow_Title
                case .voiceCalls:
                    title = strings.Privacy_Calls_NeverAllow_Title
                case .profilePhoto:
                    title = strings.Privacy_ProfilePhoto_NeverShareWith_Title
                case .forwards:
                    title = strings.Privacy_Forwards_NeverAllow_Title
                case .phoneNumber:
                    title = strings.PrivacyLastSeenSettings_NeverShareWith_Title
            }
        }
        var peerIds: [PeerId: SelectivePrivacyPeer] = [:]
        updateState { state in
            if enable {
                switch target {
                    case .main:
                        peerIds = state.enableFor
                    case .callP2P:
                        if let callP2PEnableFor = state.callP2PEnableFor {
                            peerIds = callP2PEnableFor
                        }
                }
            } else {
                switch target {
                    case .main:
                        peerIds = state.disableFor
                    case .callP2P:
                        if let callP2PDisableFor = state.callP2PDisableFor {
                            peerIds = callP2PDisableFor
                        }
                }
            }
            return state
        }
        if peerIds.isEmpty {
            let controller = ContactMultiselectionController(context: context, mode: .peerSelection(searchChatList: true, searchGroups: true), options: [])
            addPeerDisposable.set((controller.result
            |> take(1)
            |> deliverOnMainQueue).start(next: { [weak controller] peerIds in
                if peerIds.isEmpty {
                    controller?.dismiss()
                    return
                }
                let _ = (context.account.postbox.transaction { transaction -> [PeerId: SelectivePrivacyPeer] in
                    var updatedPeers: [PeerId: SelectivePrivacyPeer] = [:]
                    var existingIds = Set(updatedPeers.values.map { $0.peer.id })
                    for peerId in peerIds {
                        guard case let .peer(peerId) = peerId else {
                            continue
                        }
                        if let peer = transaction.getPeer(peerId), !existingIds.contains(peerId) {
                            existingIds.insert(peerId)
                            var participantCount: Int32?
                            if let channel = peer as? TelegramChannel, case .group = channel.info {
                                if let cachedData = transaction.getPeerCachedData(peerId: peerId) as? CachedChannelData {
                                    participantCount = cachedData.participantsSummary.memberCount
                                }
                            }
                            
                            updatedPeers[peer.id] = SelectivePrivacyPeer(peer: peer, participantCount: participantCount)
                        }
                    }
                    return updatedPeers
                }
                |> deliverOnMainQueue).start(next: { updatedPeerIds in
                    controller?.dismiss()
                    
                    updateState { state in
                        var state = state
                        if enable {
                            switch target {
                                case .main:
                                    var disableFor = state.disableFor
                                    for (key, _) in updatedPeerIds {
                                        disableFor.removeValue(forKey: key)
                                    }
                                    return state.withUpdatedEnableFor(updatedPeerIds).withUpdatedDisableFor(disableFor)
                                case .callP2P:
                                    var callP2PDisableFor = state.callP2PDisableFor ?? [:]
                                    for (key, _) in updatedPeerIds {
                                        callP2PDisableFor.removeValue(forKey: key)
                                    }
                                    return state.withUpdatedCallP2PEnableFor(updatedPeerIds).withUpdatedCallP2PDisableFor(callP2PDisableFor)
                            }
                        } else {
                            switch target {
                                case .main:
                                    var enableFor = state.enableFor
                                    for (key, _) in updatedPeerIds {
                                        enableFor.removeValue(forKey: key)
                                    }
                                    return state.withUpdatedDisableFor(updatedPeerIds).withUpdatedEnableFor(enableFor)
                                case .callP2P:
                                    var callP2PEnableFor = state.callP2PEnableFor ?? [:]
                                    for (key, _) in updatedPeerIds {
                                        callP2PEnableFor.removeValue(forKey: key)
                                    }
                                    return state.withUpdatedCallP2PDisableFor(updatedPeerIds).withUpdatedCallP2PEnableFor(callP2PEnableFor)
                            }
                        }
                    }
                    
                    let controller = selectivePrivacyPeersController(context: context, title: title, initialPeers: updatedPeerIds, updated: { updatedPeerIds in
                        updateState { state in
                            if enable {
                                switch target {
                                    case .main:
                                        var disableFor = state.disableFor
                                        for (key, _) in updatedPeerIds {
                                            disableFor.removeValue(forKey: key)
                                        }
                                        return state.withUpdatedEnableFor(updatedPeerIds).withUpdatedDisableFor(disableFor)
                                    case .callP2P:
                                        var callP2PDisableFor = state.callP2PDisableFor ?? [:]
                                        for (key, _) in updatedPeerIds {
                                            callP2PDisableFor.removeValue(forKey: key)
                                        }
                                        return state.withUpdatedCallP2PEnableFor(updatedPeerIds).withUpdatedCallP2PDisableFor(callP2PDisableFor)
                                }
                            } else {
                                switch target {
                                    case .main:
                                        var enableFor = state.enableFor
                                        for (key, _) in updatedPeerIds {
                                            enableFor.removeValue(forKey: key)
                                        }
                                        return state.withUpdatedDisableFor(updatedPeerIds).withUpdatedEnableFor(enableFor)
                                    case .callP2P:
                                        var callP2PEnableFor = state.callP2PEnableFor ?? [:]
                                        for (key, _) in updatedPeerIds {
                                            callP2PEnableFor.removeValue(forKey: key)
                                        }
                                        return state.withUpdatedCallP2PDisableFor(updatedPeerIds).withUpdatedCallP2PEnableFor(callP2PEnableFor)
                                }
                            }
                        }
                    })
                    pushControllerImpl?(controller, false)
                })
            }))
            presentControllerImpl?(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
        } else {
            let controller = selectivePrivacyPeersController(context: context, title: title, initialPeers: peerIds, updated: { updatedPeerIds in
                updateState { state in
                    if enable {
                        switch target {
                            case .main:
                                var disableFor = state.disableFor
                                for (key, _) in updatedPeerIds {
                                    disableFor.removeValue(forKey: key)
                                }
                                return state.withUpdatedEnableFor(updatedPeerIds).withUpdatedDisableFor(disableFor)
                            case .callP2P:
                                var callP2PDisableFor = state.callP2PDisableFor ?? [:]
                                for (key, _) in updatedPeerIds {
                                    callP2PDisableFor.removeValue(forKey: key)
                                }
                                return state.withUpdatedCallP2PEnableFor(updatedPeerIds).withUpdatedCallP2PDisableFor(callP2PDisableFor)
                        }
                    } else {
                        switch target {
                            case .main:
                                var enableFor = state.enableFor
                                for (key, _) in updatedPeerIds {
                                    enableFor.removeValue(forKey: key)
                                }
                                return state.withUpdatedDisableFor(updatedPeerIds).withUpdatedEnableFor(enableFor)
                            case .callP2P:
                                var callP2PEnableFor = state.callP2PEnableFor ?? [:]
                                for (key, _) in updatedPeerIds {
                                    callP2PEnableFor.removeValue(forKey: key)
                                }
                                return state.withUpdatedCallP2PDisableFor(updatedPeerIds).withUpdatedCallP2PEnableFor(callP2PEnableFor)
                        }
                    }
                }
            })
            pushControllerImpl?(controller, true)
        }
    }, updateCallP2PMode: { mode in
        updateState { state in
            return state.withUpdatedCallP2PMode(mode)
        }
    }, updateCallIntegrationEnabled: { enabled in
         updateState { state in
            return state.withUpdatedCallsIntegrationEnabled(enabled)
        }
        let _ = updateVoiceCallSettingsSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
            var settings = settings
            settings.enableSystemIntegration = enabled
            return settings
        }).start()
    })
    
    let peerName = context.account.postbox.transaction { transaction -> String in
        return (transaction.getPeer(context.account.peerId) as? TelegramUser)?.displayTitle ?? ""
    }
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get(), peerName) |> deliverOnMainQueue
    |> map { presentationData, state, peerName -> (ItemListControllerState, (ItemListNodeState<SelectivePrivacySettingsEntry>, SelectivePrivacySettingsEntry.ItemGenerationArguments)) in
        
        let title: String
        switch kind {
            case .presence:
                title = presentationData.strings.PrivacySettings_LastSeenTitle
            case .groupInvitations:
                title = presentationData.strings.Privacy_GroupsAndChannels
            case .voiceCalls:
                title = presentationData.strings.Settings_CallSettings
            case .profilePhoto:
                title = presentationData.strings.Privacy_ProfilePhoto
            case .forwards:
                title = presentationData.strings.Privacy_Forwards
            case .phoneNumber:
                title = presentationData.strings.Privacy_PhoneNumber
        }
        let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(entries: selectivePrivacySettingsControllerEntries(presentationData: presentationData, kind: kind, state: state, peerName: peerName), style: .blocks, animateChanges: false)
        
        return (controllerState, (listState, arguments))
    } |> afterDisposed {
        actionsDisposable.dispose()
    }
    
    struct AppliedSettings: Equatable {
        let settings: SelectivePrivacySettings
        let callP2PSettings: SelectivePrivacySettings?
        let callDataSaving: VoiceCallDataSaving?
        let callIntegrationEnabled: Bool?
    }
    
    var appliedSettings: AppliedSettings?
    
    let update: (Bool) -> Void = { save in
        var wasSaving = false
        var settings: SelectivePrivacySettings?
        var callP2PSettings: SelectivePrivacySettings?
        var callDataSaving: VoiceCallDataSaving?
        var callIntegrationEnabled: Bool?
        updateState { state in
            wasSaving = state.saving
            callDataSaving = state.callDataSaving
            callIntegrationEnabled = state.callIntegrationEnabled
            switch state.setting {
                case .everybody:
                    settings = SelectivePrivacySettings.enableEveryone(disableFor: state.disableFor)
                case .contacts:
                    settings = SelectivePrivacySettings.enableContacts(enableFor: state.enableFor, disableFor: state.disableFor)
                case .nobody:
                    settings = SelectivePrivacySettings.disableEveryone(enableFor: state.enableFor)
            }
            
            if case .voiceCalls = kind, let callP2PMode = state.callP2PMode, let disableFor = state.callP2PDisableFor, let enableFor = state.callP2PEnableFor {
                switch callP2PMode {
                    case .everybody:
                        callP2PSettings = SelectivePrivacySettings.enableEveryone(disableFor: disableFor)
                    case .contacts:
                        callP2PSettings = SelectivePrivacySettings.enableContacts(enableFor: enableFor, disableFor: disableFor)
                    case .nobody:
                        callP2PSettings = SelectivePrivacySettings.disableEveryone(enableFor: enableFor)
                }
            }
            
            return state.withUpdatedSaving(true)
        }
        
        if let settings = settings, !wasSaving {
            let settingsToApply = AppliedSettings(settings: settings, callP2PSettings: callP2PSettings, callDataSaving: callDataSaving, callIntegrationEnabled: callIntegrationEnabled)
            if appliedSettings == settingsToApply {
                return
            }
            appliedSettings = settingsToApply
            
            let type: UpdateSelectiveAccountPrivacySettingsType
            switch kind {
                case .presence:
                    type = .presence
                case .groupInvitations:
                    type = .groupInvitations
                case .voiceCalls:
                    type = .voiceCalls
                case .profilePhoto:
                    type = .profilePhoto
                case .forwards:
                    type = .forwards
                case .phoneNumber:
                    type = .phoneNumber
            }
            
            let updateSettingsSignal = updateSelectiveAccountPrivacySettings(account: context.account, type: type, settings: settings)
            var updateCallP2PSettingsSignal: Signal<Void, NoError> = Signal.complete()
            if let callP2PSettings = callP2PSettings {
                updateCallP2PSettingsSignal = updateSelectiveAccountPrivacySettings(account: context.account, type: .voiceCallsP2P, settings: callP2PSettings)
            }
            
            let _ = (combineLatest(updateSettingsSignal, updateCallP2PSettingsSignal) |> deliverOnMainQueue).start(completed: {
            })
            
            if case .voiceCalls = kind, let dataSaving = callDataSaving, let callP2PSettings = callP2PSettings, let systemIntegrationEnabled = callIntegrationEnabled {
                updated(settings, (callP2PSettings, VoiceCallSettings(dataSaving: dataSaving, enableSystemIntegration: systemIntegrationEnabled)))
            } else {
                updated(settings, nil)
            }
        }
    }
    
    let controller = ItemListController(context: context, state: signal)
    controller.willDisappear = { [weak controller] _ in
        if let controller = controller, let navigationController = controller.navigationController {
            let index = navigationController.viewControllers.firstIndex(of: controller)
            if index == nil || index == navigationController.viewControllers.count - 1 {
                update(true)
            }
        }
    }
    controller.didDisappear = { [weak controller] _ in
        if let controller = controller, controller.navigationController?.viewControllers.firstIndex(of: controller) == nil {
            //update(true)
        }
    }
    
    pushControllerImpl = { [weak controller] c, animated in
        (controller?.navigationController as? NavigationController)?.pushViewController(c, animated: animated)
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    dismissImpl = { [weak controller] in
        let _ = (controller?.navigationController as? NavigationController)?.popViewController(animated: true)
    }
    
    return controller
}