// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*
    Errors:
    E1: No authority
    E2: Invalid namespace
    E3: Invalid name 
    E4: Name expired
    E5: Array count mismatch
    E6: Fee not enough
    E7: Namespace already exists
    E8: Cannot modify price
    E9: Invalid price
    E10: Too many custom price names
    E11: Already open
    E12: Already disabled
    E13: Not open yet
    E14: Cannot receive name
    E15: Not support ping
    E16: Content too long
    E17: Key mismatch
    E18: Invalid key
    E19: Too many keys
    E20: Transfer not allowed
    E21: Not need renewal
    E22: Not expired yet
    E23: Invalid lifetime
    E24: Invalid times
    E25: Transfer not allow: to whom already own non-expired name
    E26: Invalid renewal price param
*/

import "./ReentrancyGuard.sol";
import "./ERC721.sol";

contract DecentralName is ReentrancyGuard, ERC721 {
    uint256 constant public MAX_PROFILE_KEY_COUNT = 200;
    uint256 constant public MAX_CUSTOM_PRICE_NAMES_COUNT = 200;
    uint256 constant public MAX_RENEWAL_TIMES_PER_TIMES = 20;
    uint256[] public NAMESPACE_PRICE_LIST = [250 ether, 50 ether, 40 ether, 20 ether, 10 ether, 5 ether, 5 ether, 2 ether];

    event BuyNamespace(bytes32 indexed namespace);
    event TransferNamespaceAdmin(bytes32 indexed namespace, address admin);
    event SetNamespaceBeneficiary(bytes32 indexed namespace, address beneficiary);
    event SetNamespaceDesc(bytes32 indexed namespace);
    event SetPrice(bytes32 indexed namespace);
    event SetCustomPrice(bytes32 indexed namespace);
    event OpenNamespace(bytes32 indexed namespace);
    event DisableModifyPrice(bytes32 indexed namespace);
    event AssignName(bytes32 indexed namespace, bytes32 indexed name, address user);
    event Renewal(bytes32 indexed namespace, bytes32 indexed name);
    event Ping(bytes32 indexed namespace, bytes32 indexed name);
    event SetProfile(bytes32 indexed namespace, bytes32 indexed name);

    struct NamespaceInfo {
        address admin;                  // Who can modify the namespace's attributes
        address payable beneficiary;    // Where the registration/renewal fee goes to
        bytes desc;                     // Length <= 256, shown as innerHTML. e.g., "visit <a href="https://nostr.com" target="_blank">nostr.com</a> for more info".
        uint256 startStamp;             // When was the namespace created
        uint256 openStamp;              // When was the namespace open for registration(i.e., anyone can register through current contract)
        uint256 renewalLifetime;        // Renewal period, 0 means not need renewal.
        uint256 pingLifetime;           // Only makes sense when renewalLifetime == 0. If pingLifetime > 0, user must ping before pingExpiredStamp(only cost gas fee), otherwise the name is expired.
        uint256[25] registerPriceList;  // 1d, 1L, _, 2d, 2L, 2Misc, 3d, 3L, 3Misc, 4d, 4L, 4Misc, 5d, 5L, 5Misc, 6d, 6L, 6Misc, 7d, 7L, 7Misc, 8d, 8L, 8Misc, remain.
        uint256 renewalPriceParam;      // renewalPriceParam = a * 1000000 + b * 1000 + c, Renewal-fee = (a + b * Registration-fee) / c
        bool bAllowModifyPrice;         // Can namespace admin modify price?
        bytes32[] customPriceNames;     // Custom registration prices for at most MAX_CUSTOM_PRICE_NAMES_COUNT names.
    }

    struct NameInfo {
        bytes32 namespace;
        bytes32 name;
        uint256 renewalExpiredStamp;
        uint256 pingExpiredStamp;
        bytes32[] profileKeyList; // display name, avatar, bio, url, nostr, email, btc, lightning, ..
    }

    bytes32[] public namespaceList;
    mapping(bytes32 => NamespaceInfo) public namespaceMap;                      // namespace => NamespaceInfo
    mapping(bytes32 => mapping(bytes32 => uint256)) public customPriceNamesMap; // namespace => (name => custom-price)

    uint256 public curTokenId = 0;
    mapping(address => uint256) public addr2TokenIdMap;                         // address => tokenId
    mapping(uint256 => NameInfo) public id2NameInfoMap;                         // tokenId => NameInfo
    mapping(uint256 => mapping(bytes32 => bytes)) public id2ProfileValueMap;    // tokenId => (profile-key => profile-value)
    mapping(bytes32 => mapping(bytes32 => uint256)) public name2IdMap;          // (namespace => (name => tokenId))

    constructor() ERC721("DecentralName", "DNAME") {
        _initGenesis();
    }

    //////// Frequent
    function resolveAddress(address user) public view returns (bool bResult, uint256 tokenId, bytes32 namespace, bytes32 name) {
        tokenId = addr2TokenIdMap[user];
        if (tokenId > 0) {
            (bResult, namespace, name) = resolveTokenId(tokenId);
        }
    }

    function resolveAddressFull(address user) public view returns (bool bResult, uint256 tokenId, NameInfo memory nameInfo, bytes[] memory profileValueList) {
        (bResult, tokenId, nameInfo.namespace, nameInfo.name) = resolveAddress(user);
        if (bResult) {
            (, , profileValueList) = getProfileKeysAndValues(nameInfo.namespace, nameInfo.name);
            nameInfo = id2NameInfoMap[tokenId];
        }
    }

    function resolveName(bytes32 namespace, bytes32 name) public view returns (bool bResult, address owner) {
        uint256 tokenId = name2IdMap[namespace][name];
        if (tokenId > 0) {
            owner = ownerOf(tokenId);
            NameInfo storage nInfo = id2NameInfoMap[tokenId];
            if (!_isNameExpired(namespaceMap[nInfo.namespace], nInfo)) {
                bResult = true;
            }
        }
    }

    function resolveNameFull(bytes32 namespace, bytes32 name) public view returns (bool bResult, uint256 tokenId, address owner, NameInfo memory nameInfo, bytes[] memory profileValueList) {
        (bResult, ,profileValueList) = getProfileKeysAndValues(namespace, name);
        if (bResult) {
            tokenId = name2IdMap[namespace][name];
            owner = ownerOf(tokenId);
            nameInfo = id2NameInfoMap[tokenId];
        }
    }

    // Query many names to register
    function queryManyNames(bytes32[] calldata inNamespaceList, bytes32[] calldata inNameList) public view returns (bool[] memory resultList, address[] memory ownerList, uint256[] memory priceList) {
        uint256 nameListLen = inNameList.length;
        require(nameListLen == inNamespaceList.length, 'E5');
        resultList = new bool[](nameListLen);
        ownerList = new address[](nameListLen);
        priceList = new uint256[](nameListLen);
        for (uint256 i; i < nameListLen; ++i) {
            uint256 tokenId = name2IdMap[inNamespaceList[i]][inNameList[i]];
            NamespaceInfo storage nsInfo = namespaceMap[inNamespaceList[i]];
            if (tokenId > 0 && !_isNameExpired(nsInfo, id2NameInfoMap[tokenId])) {
                resultList[i] = false;
                ownerList[i] = ownerOf(tokenId);
            } else if (nsInfo.openStamp > 0) {
                resultList[i] = true;
                (, priceList[i]) = getRegistrationPrice(inNamespaceList[i], inNameList[i]);
            }
        }
    }

    function resolveTokenId(uint256 tokenId) public view returns (bool bResult, bytes32 namespace, bytes32 name) {
        NameInfo storage nInfo = id2NameInfoMap[tokenId];
        NamespaceInfo storage nsInfo = namespaceMap[nInfo.namespace];
        if (nsInfo.startStamp > 0 && !_isNameExpired(nsInfo, nInfo)) {
            bResult = true;
            namespace = nInfo.namespace;
            name = nInfo.name;
        }
    }

    function getNamespaceInfos(bytes32[] memory inNamespaceList) public view returns (NamespaceInfo[] memory results) {
        uint256 listLen = inNamespaceList.length;
        results = new NamespaceInfo[](listLen);
        for (uint256 i; i < listLen; ++i) {
            results[i] = namespaceMap[inNamespaceList[i]];
        }
    }

    function getFullNamespaceInfos() public view returns (bytes32[] memory outNamespaceList, NamespaceInfo[] memory results) {
        outNamespaceList = namespaceList;
        results = getNamespaceInfos(namespaceList);
    }

    //////// Namespace
    function getNamespacePrice(bytes32 namespace) public view returns (bool bResult, uint256 price) {
        (bool bOk, uint256 alphaNum, uint256 digitNum, uint256 underscoreNum) = parseName(namespace);
        if (bOk && (namespace[0] >= 0x61 && namespace[0] <= 0x7a)) {  // For namespace, first character must be lower-case-alpha
            bResult = true;
            uint256 totalLen = alphaNum + digitNum + underscoreNum;
            if (totalLen <= NAMESPACE_PRICE_LIST.length) {
                price = NAMESPACE_PRICE_LIST[totalLen - 1];
            } else {
                price = NAMESPACE_PRICE_LIST[NAMESPACE_PRICE_LIST.length - 1];
            }
        }
    }

    function buyNamespace(bytes32 namespace, uint256 renewalLifetime, uint256 pingLifetime) payable external nonReentrant {
        (bool bOk, uint256 price) = getNamespacePrice(namespace);
        require(bOk, 'E2');
        require(renewalLifetime == 0 || (renewalLifetime >= 1 days && renewalLifetime <= 36500 days), 'E23');
        if (renewalLifetime > 0) {
            require(pingLifetime == 0, 'E23');
        } else {
            require(pingLifetime == 0 || (pingLifetime >= 1 days && pingLifetime <= 36500 days), 'E23');
        }
        require(msg.value == price, 'E6');
        payable(0).transfer(price); // burn

        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.startStamp == 0, 'E7');
        namespaceList.push(namespace);

        nsInfo.admin = msg.sender;
        nsInfo.beneficiary = payable(msg.sender);
        // nsInfo.desc
        nsInfo.startStamp = block.timestamp;
        // nsInfo.openStamp
        nsInfo.renewalLifetime = renewalLifetime;
        nsInfo.pingLifetime = pingLifetime;
        // nsInfo.registerPriceList
        // nsInfo.renewalPriceParam
        nsInfo.bAllowModifyPrice = true;
        // nsInfo.customPriceNames

        emit BuyNamespace(namespace);
    }

    function transferNamespaceAdmin(bytes32 namespace, address admin) external nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.admin == msg.sender, 'E1');
        nsInfo.admin = admin;
        emit TransferNamespaceAdmin(namespace, admin);
    }

    function setNamespaceBeneficiary(bytes32 namespace, address payable beneficiary) external nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.admin == msg.sender || nsInfo.beneficiary == msg.sender, 'E1');
        nsInfo.beneficiary = beneficiary;
        emit SetNamespaceBeneficiary(namespace, beneficiary);
    }

    function setNamespaceDesc(bytes32 namespace, bytes calldata desc) external nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.admin == msg.sender, 'E1');
        require(desc.length <= 256, 'E16');
        nsInfo.desc = desc;
        emit SetNamespaceDesc(namespace);
    }

    function setPrice(bytes32 namespace, uint256[25] calldata registerPriceList, uint256 renewalPriceParam) external nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.admin == msg.sender, 'E1');
        require(nsInfo.bAllowModifyPrice, 'E8');
        require(nsInfo.renewalLifetime == 0 || renewalPriceParam % 1000 != 0, 'E26');
        nsInfo.registerPriceList = registerPriceList;
        nsInfo.renewalPriceParam = renewalPriceParam;
        emit SetPrice(namespace);
    }

    function setCustomPrice(bytes32 namespace, bytes32[] calldata nameList, uint256[] calldata priceList) external nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.admin == msg.sender, 'E1');
        require(nsInfo.bAllowModifyPrice, 'E8');
        uint256 nameLen = nameList.length;
        require(nameLen == priceList.length, 'E5');
        bytes32[] storage customNames = nsInfo.customPriceNames;
        mapping(bytes32 => uint256) storage priceMap = customPriceNamesMap[namespace];
        for (uint256 i; i < nameLen; ) {
            bytes32 name = nameList[i];
            if (priceMap[name] == 0) {
                require(isNameValid(name), 'E3');
                customNames.push(name);
            }
            require(priceList[i] > 0, 'E9'); // i.e., not allow cancel set custom name price
            priceMap[name] = priceList[i];
            unchecked {
                ++i;
            }
        }
        require(customNames.length <= MAX_CUSTOM_PRICE_NAMES_COUNT, 'E10');
        emit SetCustomPrice(namespace);
    }

    function getCustomPriceInfo(bytes32 namespace) public view returns (bytes32[] memory nameList, uint256[] memory priceList) {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        nameList = nsInfo.customPriceNames;
        uint256 nameListLen = nameList.length;
        priceList = new uint256[](nameListLen);
        mapping(bytes32 => uint256) storage priceMap = customPriceNamesMap[namespace];
        for (uint256 i; i < nameListLen; ++i) {
            priceList[i] = priceMap[nameList[i]];
        }
    }

    // Open registration, so that anyone can register through current contract; Otherwise, only admin can register through registerMany(with bByAdmin=true)
    function openRegistration(bytes32 namespace) external nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.admin == msg.sender, 'E1');
        require(nsInfo.openStamp == 0, 'E11');
        require(nsInfo.renewalLifetime == 0 || nsInfo.renewalPriceParam % 1000 != 0, 'E26');
        nsInfo.openStamp = block.timestamp;
        emit OpenNamespace(namespace);
    }

    function disableModifyPrice(bytes32 namespace) external nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.admin == msg.sender, 'E1');
        require(nsInfo.bAllowModifyPrice, 'E12');
        require(nsInfo.renewalLifetime == 0 || nsInfo.renewalPriceParam % 1000 != 0, 'E26');
        nsInfo.bAllowModifyPrice = false;
        emit DisableModifyPrice(namespace);
    }

    //////// Name
    function register(bytes32 namespace, bytes32 name) external payable nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.openStamp > 0, 'E13');
        (bool bCanReceiveName,) = _canReceiveName(msg.sender);
        require(bCanReceiveName, 'E14');
        (bool bOk, uint256 price) = getRegistrationPrice(namespace, name);
        require(bOk, 'E3');
        if (price > 0) {
            require(msg.value >= price, 'E6');
            nsInfo.beneficiary.transfer(msg.value);
        }
        _assignNameToUser(namespace, name, msg.sender);
    }

    // Force register name. If current address already owns non-expired name, burn it firstly
    function forceRegister(bytes32 namespace, bytes32 name) external payable nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.openStamp > 0, 'E13');
        (bool bCanReceiveName, uint256 tokenId) = _canReceiveName(msg.sender);
        if (!bCanReceiveName) {
            _removeItem(tokenId);
        }
        (bool bOk, uint256 price) = getRegistrationPrice(namespace, name);
        require(bOk, 'E3');
        if (price > 0) {
            require(msg.value >= price, 'E6');
            nsInfo.beneficiary.transfer(msg.value);
        }
        _assignNameToUser(namespace, name, msg.sender);
    }

    function registerMany(bool bByAdmin, bytes32 namespace, bytes32[] calldata nameList, address[] calldata userList) external payable nonReentrant returns (address[] memory failList, uint256 failCount) {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        if (bByAdmin) {
            require(nsInfo.admin == msg.sender, 'E1');
        } else {
            require(nsInfo.openStamp > 0, 'E13');
        }
        
        uint256 nameLen = nameList.length;
        require(nameLen == userList.length, 'E5');
        failList = new address[](nameLen);
        uint256 totalFee = 0;
        for (uint256 i; i < nameLen; ) {
            require(userList[i] != address(0), 'E14');
            (bool bCanReceiveName,) = _canReceiveName(userList[i]);
            if (bCanReceiveName) {
                if (bByAdmin) {
                    require(isNameValid(nameList[i]), 'E3');
                } else {
                    (bool bResult, uint256 price) = getRegistrationPrice(namespace, nameList[i]);
                    require(bResult, 'E3');
                    totalFee += price;
                }
                _assignNameToUser(namespace, nameList[i], userList[i]);
            } else {
                failList[failCount++] = userList[i];
            }
            unchecked {
                ++i;
            }
        }

        if (totalFee > 0) {
            require(totalFee <= msg.value, 'E6');
            nsInfo.beneficiary.transfer(totalFee);
        }
        if (totalFee < msg.value) {
            payable(msg.sender).transfer(msg.value - totalFee);
        }
    }

    function renewal(bytes32 namespace, bytes32 name, uint256 times) external payable nonReentrant returns (bool bResult) {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(times >= 1 && times <= MAX_RENEWAL_TIMES_PER_TIMES, 'E24');
        require(nsInfo.renewalLifetime > 0, 'E21');
        uint256 tokenId = name2IdMap[namespace][name];
        if (tokenId > 0) {
            NameInfo storage nInfo = id2NameInfoMap[tokenId];
            if (!_isNameExpired(nsInfo, nInfo)) {
                (, uint256 renewalPrice) = getRenewalPrice(namespace, name);
                if (renewalPrice > 0) {
                    require(msg.value >= renewalPrice * times, 'E6');
                    nsInfo.beneficiary.transfer(msg.value);
                }
                nInfo.renewalExpiredStamp = nInfo.renewalExpiredStamp + times * nsInfo.renewalLifetime;
                emit Renewal(namespace, name);
                bResult = true;
            }
        }
    }

    function renewalMany(bool bByAdmin, bytes32 namespace, bytes32[] calldata nameList, uint256[] calldata timesList) external payable nonReentrant returns (bytes32[] memory failList, uint256 failCount) {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        if (bByAdmin) {
            require(nsInfo.admin == msg.sender, 'E1');
        }
        require(nsInfo.renewalLifetime > 0, 'E21');
        uint256 nameLen = nameList.length;
        require(nameLen == timesList.length, 'E5');
        failList = new bytes32[](nameLen);
        uint256 totalFee = 0;
        for (uint256 i; i < nameLen; ) {
            bytes32 name = nameList[i];
            uint256 tokenId = name2IdMap[namespace][name];
            if (tokenId > 0) {
                NameInfo storage nInfo = id2NameInfoMap[tokenId];
                if (!_isNameExpired(nsInfo, nInfo)) {
                    if (!bByAdmin) {
                        (, uint256 renewalPrice) = getRenewalPrice(namespace, name);
                        totalFee += renewalPrice * timesList[i];
                    }
                    require(timesList[i] >= 1 && timesList[i] <= MAX_RENEWAL_TIMES_PER_TIMES, 'E24');
                    nInfo.renewalExpiredStamp = nInfo.renewalExpiredStamp + timesList[i] * nsInfo.renewalLifetime;
                    emit Renewal(namespace, name);
                } else {
                    failList[failCount++] = name;
                }
            } else {
                failList[failCount++] = name;
            }
            unchecked {
                ++i;
            }
        }

        if (totalFee > 0) {
            require(totalFee <= msg.value, 'E6');
            nsInfo.beneficiary.transfer(totalFee);
            if (totalFee < msg.value) {
                payable(msg.sender).transfer(msg.value - totalFee);
            }
        }
        return (failList, failCount);
    }

    function ping(bytes32 namespace, bytes32 name) external nonReentrant {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        require(nsInfo.renewalLifetime == 0 && nsInfo.pingLifetime > 0, 'E15');
        uint256 tokenId = name2IdMap[namespace][name];
        require(ownerOf(tokenId) == msg.sender, 'E1');
        NameInfo storage nInfo = id2NameInfoMap[tokenId];
        require(block.timestamp <= nInfo.pingExpiredStamp, 'E4');
        nInfo.pingExpiredStamp = block.timestamp + nsInfo.pingLifetime;
        emit Ping(namespace, name);
    }

    function getRegistrationPrice(bytes32 namespace, bytes32 name) public view returns (bool, uint256) {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        if (nsInfo.startStamp == 0) {
            return (false, 0);
        }

        uint256 customPrice = customPriceNamesMap[namespace][name];
        if (customPrice > 0) {
            return (true, customPrice);
        }

        (bool bOk, uint256 alphaNum, uint256 digitNum, uint256 underscoreNum) = parseName(name);
        if (!bOk) {
            return (false, 0);
        }
        uint256 totalLen = alphaNum + digitNum + underscoreNum;
        if (totalLen <= 8) {
            if (underscoreNum == 0 && (alphaNum == 0 || digitNum == 0)) { // pure-alpha or pure-digit or empty
                if (digitNum > 0) {
                    return (true, nsInfo.registerPriceList[(totalLen - 1) * 3]);
                } else if (alphaNum > 0) {
                    return (true, nsInfo.registerPriceList[totalLen * 3 - 2]);
                } else {
                    return (false, 0);
                }
            } else { // Misc
                return (true, nsInfo.registerPriceList[totalLen * 3 - 1]);
            }
        }
        return (true, nsInfo.registerPriceList[nsInfo.registerPriceList.length - 1]);
    }

    function getRenewalPrice(bytes32 namespace, bytes32 name) public view returns (bool, uint256) {
        (bool bOk, uint256 regPrice) = getRegistrationPrice(namespace, name);
        if (bOk) {
            NamespaceInfo storage nsInfo = namespaceMap[namespace];
            if (nsInfo.renewalLifetime == 0) {
                return (true, 0);   // not need renewal
            }
            uint256 param = nsInfo.renewalPriceParam;
            return (true, ((param/1000000) + ((param/1000)%1000) * regPrice) / (param % 1000));
        }
        return (false, 0);
    }

    function parseName(bytes32 name) public pure returns (bool, uint256, uint256, uint256) {
        bool bReachEnd = false;
        uint256 alphaNum = 0;
        uint256 digitNum = 0;
        uint256 underscoreNum = 0;
        for (uint256 i; i < 32; ) {
            bytes1 ch = name[i];
            if (ch > 0) {
                if (bReachEnd) {
                    return (false, 0, 0, 0);
                }
                if (ch >= 0x61 && ch <= 0x7a) {
                    ++alphaNum;
                } else if (ch >= 0x30 && ch <= 0x39) {
                    ++digitNum;
                } else if (ch == 0x5f) {
                    ++underscoreNum;
                } else {
                    return (false, 0, 0, 0);
                }
            } else {
                if (!bReachEnd) {
                    bReachEnd = true;
                }
            }
            unchecked {
                ++i;
            }
        }

        if (alphaNum == 0 && digitNum == 0 && underscoreNum == 0) {
            return (false, 0, 0, 0);
        }
        return (true, alphaNum, digitNum, underscoreNum);
    }

    function canReceiveName(address user) public view returns (bool bCanReceiveName) {
        (bCanReceiveName, ) = _canReceiveName(user);
    }

    function canRegisterName(bytes32 namespace, bytes32 name) public view returns (bool) {
        return canRegisterName(namespace, name, true);
    }

    function canRegisterName(bytes32 namespace, bytes32 name, bool bCheckOpen) public view returns (bool) {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        if (nsInfo.startStamp == 0) {
            return false;
        }
        if (bCheckOpen && nsInfo.openStamp == 0) {
            return false;
        }
        if (!isNameValid(name)) {
            return false;
        }
        uint256 tokenId = name2IdMap[namespace][name];
        if (tokenId == 0) {
            return true;
        }
        return _isNameExpired(nsInfo, id2NameInfoMap[tokenId]);
    }

    function isNameValid(bytes32 name) public pure returns (bool) {
        uint256 flag = 0;
        for (uint256 i = 0; i < 32; ++i) {
            bytes1 ch = name[i];
            if (ch > 0) {
                if (flag == 2) {
                    return false;
                } else {
                    flag = 1;
                }
                if ((ch < 0x61 || ch > 0x7a) && (ch < 0x30 || ch > 0x39) && ch != 0x5f) {  // not-lower-case-alpha && not-digit && not-underscore
                    return false;
                }
            } else {
                if (flag != 2) {
                    if (flag == 0) {
                        return false;
                    }
                    flag = 2;
                }
            }
        }
        return flag != 0;
    }

    // display name:    0x646973706c6179206e616d650000000000000000000000000000000000000000
    // avatar:          0x6176617461720000000000000000000000000000000000000000000000000000
    // bio:             0x62696f0000000000000000000000000000000000000000000000000000000000
    // url:             0x75726c0000000000000000000000000000000000000000000000000000000000
    // nostr:           0x6e6f737472000000000000000000000000000000000000000000000000000000
    // email:           0x656d61696c000000000000000000000000000000000000000000000000000000
    // btc:             0x6274630000000000000000000000000000000000000000000000000000000000
    // lightning:       0x6c696768746e696e670000000000000000000000000000000000000000000000
    function getProfileValue(bytes32 namespace, bytes32 name, bytes32 key) public view returns (bool bResult, bytes memory value) {
        uint256 tokenId = name2IdMap[namespace][name];
        if (tokenId > 0) {
            if (!_isNameExpired(namespaceMap[namespace], id2NameInfoMap[tokenId])) {
                bResult = true;
                value = id2ProfileValueMap[tokenId][key];
            }
        }
    }

    function getProfileKeysAndValues(bytes32 namespace, bytes32 name) public view returns (bool bResult, bytes32[] memory keyList, bytes[] memory valueList) {
        uint256 tokenId = name2IdMap[namespace][name];
        if (tokenId > 0) {
            NameInfo storage nInfo = id2NameInfoMap[tokenId];
            if (!_isNameExpired(namespaceMap[namespace], nInfo)) {
                bResult = true;
                keyList = nInfo.profileKeyList;
                uint256 keyListLen = keyList.length;
                valueList = new bytes[](keyListLen);
                mapping(bytes32 => bytes) storage profileValueMap = id2ProfileValueMap[tokenId];
                for (uint256 i; i < keyListLen; ++i) {
                    valueList[i] = profileValueMap[keyList[i]];
                }
            }
        }
    }

    // Set profile's custom key-value pairs.
    // If indexList[pos] > 0, set profileValueMap[keyList[indexList[pos]-1]] = valueList[pos];
    // Otherwise, append keyList[pos] to profileKeyList, set profileValueMap[keyList[pos]] = valueList[pos];
    function setProfileKeyValuePairs(bytes32 namespace, bytes32 name, uint256[] calldata indexList, bytes32[] calldata keyList, bytes[] calldata valueList) external nonReentrant {
        uint256 tokenId = name2IdMap[namespace][name];
        require(ownerOf(tokenId) == msg.sender, 'E1');
        NameInfo storage nInfo = id2NameInfoMap[tokenId];
        require(!_isNameExpired(namespaceMap[namespace], nInfo), 'E4');

        uint256 indexLen = indexList.length;
        require(indexLen == keyList.length, 'E5');
        require(indexLen == valueList.length, 'E5');
        mapping(bytes32 => bytes) storage profileValueMap = id2ProfileValueMap[tokenId];
        bytes32[] storage profileKeyList = nInfo.profileKeyList;
        for (uint256 pos; pos < indexLen; ) {
            require(valueList[pos].length <= 128, 'E16');
            if (indexList[pos] > 0) { // real index is curIndex - 1
                bytes32 curKey = profileKeyList[indexList[pos] - 1];
                require(curKey == keyList[pos], 'E17');
                profileValueMap[curKey] = valueList[pos];
            } else {
                bytes32 curKey = keyList[pos];
                profileKeyList.push(curKey);
                require(curKey != 0, 'E18');
                profileValueMap[curKey] = valueList[pos];
            }
            unchecked {
                ++pos;
            }
        }
        require(profileKeyList.length <= MAX_PROFILE_KEY_COUNT, 'E19');
        emit SetProfile(namespace, name);
    }

    function removeAllProfileKeys(bytes32 namespace, bytes32 name) external nonReentrant {
        uint256 tokenId = name2IdMap[namespace][name];
        require(ownerOf(tokenId) == msg.sender, 'E1');
        NameInfo storage nInfo = id2NameInfoMap[tokenId];
        require(!_isNameExpired(namespaceMap[namespace], nInfo), 'E4');
        mapping(bytes32 => bytes) storage profileValueMap = id2ProfileValueMap[tokenId];
        bytes32[] memory keyList = nInfo.profileKeyList;
        uint256 keyListLen = keyList.length;
        for (uint256 i; i < keyListLen; ) {
            delete profileValueMap[keyList[i]];
            unchecked {
                ++i;
            }
        }
        delete nInfo.profileKeyList;
    }

    //////// ERC721
    function transferFrom(address from, address to, uint256 tokenId) public override nonReentrant {
        require(to != address(0), 'E14');
        (bool bOk, ,) = resolveTokenId(tokenId);
        require(bOk, 'E20');
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override nonReentrant {
        require(to != address(0), 'E14');
        (bool bOk, ,) = resolveTokenId(tokenId);
        require(bOk, 'E20');
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return "ipfs://QmUqW8wFpcdYuk5CVFXYvpdsWjz7x9U1Yn6s9NT7f5Re8B";
    }

    // Attention: others can still register the name after burn
    function burn(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender);
        NameInfo storage nInfo = id2NameInfoMap[tokenId];
        require(!_isNameExpired(namespaceMap[nInfo.namespace], nInfo), 'E1');
        _removeItem(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        if (to != address(0)) {
            (bool bCanReceiveName, uint256 userTokenId) = _canReceiveName(to);
            require(bCanReceiveName, 'E14');
            if (userTokenId > 0) {
                _removeItem(userTokenId);
            }
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        if (from != address(0)) {
            addr2TokenIdMap[from] = 0;
        }
        if (to != address(0)) {
            addr2TokenIdMap[to] = firstTokenId;
        }
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

    //////// Private
    function _canReceiveName(address user) private view returns (bool, uint256) {
        uint256 tokenId = addr2TokenIdMap[user];
        if (tokenId == 0) {
            return (true, 0);
        }
        NameInfo storage nInfo = id2NameInfoMap[tokenId];
        return (_isNameExpired(namespaceMap[nInfo.namespace], nInfo), tokenId);
    }

    function _isNameExpired(NamespaceInfo storage nsInfo, NameInfo storage nInfo) private view returns (bool) {
        if (nsInfo.renewalLifetime > 0) {
            return block.timestamp > nInfo.renewalExpiredStamp;
        } else {
            return nsInfo.pingLifetime > 0 ? block.timestamp > nInfo.pingExpiredStamp : false;
        }
    }

    function _assignNameToUser(bytes32 namespace, bytes32 name, address user) private {
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        uint256 tokenId = name2IdMap[namespace][name];
        if (tokenId > 0) {
            NameInfo storage nInfo = id2NameInfoMap[tokenId];
            require(_isNameExpired(nsInfo, nInfo), 'E22');
            if (nsInfo.renewalLifetime > 0) {
                nInfo.renewalExpiredStamp = block.timestamp + nsInfo.renewalLifetime;
            } else {
                nInfo.pingExpiredStamp = block.timestamp + nsInfo.pingLifetime;
            }
            if (ownerOf(tokenId) != user) {
                _transfer(ownerOf(tokenId), user, tokenId);
            }
        } else {
            _mint(user, ++curTokenId);
            bytes32[] memory profileKeyList;
            NameInfo memory nInfo = NameInfo(namespace, name, 0, 0, profileKeyList);
            if (nsInfo.renewalLifetime > 0) {
                nInfo.renewalExpiredStamp = block.timestamp + nsInfo.renewalLifetime;
            } else if (nsInfo.pingLifetime > 0) {
                nInfo.pingExpiredStamp = block.timestamp + nsInfo.pingLifetime;
            }        
            id2NameInfoMap[curTokenId] = nInfo;
            name2IdMap[namespace][name] = curTokenId;
        }
        emit AssignName(namespace, name, user);
    }

    function _removeItem(uint256 tokenId) private {
        NameInfo storage nInfo = id2NameInfoMap[tokenId];
        delete name2IdMap[nInfo.namespace][nInfo.name];
        delete id2NameInfoMap[tokenId];
        _burn(tokenId);
    }

    function _initGenesisNamespace(bytes32 namespace, address beneficiary, uint256 renewalLifetime, uint256 pingLifetime, uint256 renewalPriceParam, uint256 factor1, uint256 factor2) private {
        namespaceList.push(namespace);
        NamespaceInfo storage nsInfo = namespaceMap[namespace];
        if (renewalPriceParam > 0) {
            nsInfo.admin = 0xF0296e8c771b7D422A7E1708324b4260d92D1cEe;
        }
        nsInfo.beneficiary = payable(beneficiary);
        // nsInfo.desc
        nsInfo.startStamp = block.timestamp;
        nsInfo.openStamp = block.timestamp;
        nsInfo.renewalLifetime = renewalLifetime;
        nsInfo.pingLifetime = pingLifetime;
        nsInfo.registerPriceList = [
            factor1 * 2 ether,      factor1 * 2 ether,      factor1 * 1.5 ether,
            factor2 * 0.2 ether,    factor2 * 0.2 ether,    factor2 * 0.15 ether, 
            factor2 * 0.02 ether,   factor2 * 0.02 ether,   factor2 * 0.01 ether, 
            factor2 * 0.005 ether,  factor2 * 0.005 ether,  factor2 * 0.002 ether, 
            factor2 * 0.002 ether,  factor2 * 0.002 ether,  factor2 * 0.001 ether, 
            factor2 * 0.001 ether,  factor2 * 0.001 ether,  factor2 * 0.001 ether, 
            factor2 * 0.001 ether,  factor2 * 0.001 ether,  factor2 * 0.001 ether, 
            factor2 * 0.001 ether,  factor2 * 0.001 ether,  factor2 * 0.001 ether, 
            factor2 * 0.001 ether];
        nsInfo.renewalPriceParam = renewalPriceParam;
        if (renewalPriceParam > 0) {
            nsInfo.bAllowModifyPrice = true;
        }
        /// Custom price names
        bytes32[] storage customNames = nsInfo.customPriceNames;
        mapping(bytes32 => uint256) storage priceMap = customPriceNamesMap[namespace];
        // bitcoin
        customNames.push(0x626974636f696e00000000000000000000000000000000000000000000000000);
        priceMap[0x626974636f696e00000000000000000000000000000000000000000000000000] = renewalPriceParam > 0 ? 2 ether : 50 ether;
        // satoshi
        customNames.push(0x7361746f73686900000000000000000000000000000000000000000000000000);
        priceMap[0x7361746f73686900000000000000000000000000000000000000000000000000] = renewalPriceParam > 0 ? 2 ether : 100 ether;
        // btc
        if (renewalPriceParam > 0) {
            customNames.push(0x6274630000000000000000000000000000000000000000000000000000000000);
            priceMap[0x6274630000000000000000000000000000000000000000000000000000000000] = 2 ether;
        }
    }

    function _initGenesis() private {
        _initGenesisNamespace(0x6200000000000000000000000000000000000000000000000000000000000000, 0x03f4151815694F171B85289Fe8893C24B7876C0f, 0, 2555 days, 0, 10, 10);     // .b namespace. Desc: .b has a great meaning!
        _initGenesisNamespace(0x6400000000000000000000000000000000000000000000000000000000000000, 0x15Fc64076b132aca3daE4870a345C71d9c9eD86C, 0, 0, 0, 10, 10);             // .d namespace. Desc: .d means decentralized.
        _initGenesisNamespace(0x7361740000000000000000000000000000000000000000000000000000000000, 0x96ce96Eaf270Ff9df6dD613c83126135d93Ec041, 365 days, 0, 1001, 1, 5);     // .sat namespace. Desc: With 20 million coins, that gives each coin a value ofabout $10 million. — Hal Finney
        _initGenesisNamespace(0x6269747300000000000000000000000000000000000000000000000000000000, 0xEE6F84C8FFAeAAAd2D9688fF5acE664fb5b21E85, 0, 0, 0, 10, 10);             // .bits namespace. Desc: Why you should register .bits name: <a href="https://x.com/adam3us/status/1662136034514157575?s=20" target="_blank">nostr.com</a>.
        _initGenesisNamespace(0x6e6f737472000000000000000000000000000000000000000000000000000000, 0xF0296e8c771b7D422A7E1708324b4260d92D1cEe, 0, 0, 0, 10, 10);             // .nostr namespace. Desc: nostr is a decentralized social network, visit <a href="https://nostr.com" target="_blank">nostr.com</a> for more info.
    }
}
