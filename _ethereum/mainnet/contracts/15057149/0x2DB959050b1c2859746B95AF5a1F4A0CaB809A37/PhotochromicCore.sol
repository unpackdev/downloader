// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ENS.sol";
import "./Ownable.sol";

import "./PhotochromicRegistrar.sol";
import "./PhotochromicResolver.sol";
import "./PhotochromicTools.sol";

contract PhotochromicCore is Ownable {

    // The PhotoChromic Registrar.
    PhotochromicRegistrar public registrar;
    // The PhotoChromic Resolver.
    PhotochromicResolver public resolver;
    // The ENS registry.
    ENS public immutable ens;
    // The period in which the ticket is valid.
    uint256 public ticketValidity = 4 weeks;
    // The grace period in which a user id can not be re-registered after its expiry.
    uint256 public gracePeriod = 12 weeks;
    // Price in wei (ETH).
    uint256 public pricePerYear;

    Profile[] public profiles;
    address public photochromicSignerAddress;

    // Only for tickets!
    // Mapping between user ids and addresses.
    mapping(bytes32 => address) private nodeToAddress;
    // Mapping between addresses and corresponding domain info.
    mapping(address => bytes) private addressToDomainInfo;

    event Ticket(address indexed user, bytes32 node, string userId, string profile, uint256 yrs, uint256 timestamp);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);

    struct Profile {
        // Profile name
        string name;
        // The price of the profile.
        uint128 price;
        // The amount of socials allowed to validate.
        uint128 info;
    }

    // Information stored to handle ticket purchases.
    struct DomainInfo {
        // The user identifier for which the the ticket was bought. Full ens name.
        string userId;
        // The profile for which the user paid.
        uint8 profileNum;
        // The amount of years for which the user paid.
        uint8 yrs;
        // The time of the ticket purchase.
        uint32 purchaseTime;
    }

    struct PhotoChromicRecord {
        uint32 livenessTime;
        string[DATA_FIELDS] contents;
        string userId;
        bytes32 ipfsHash;
        EcdsaSig sig;
    }

    constructor(
        PhotochromicRegistrar _registrar,
        PhotochromicResolver _resolver,
        ENS _ens,
        address _sigAddr
    ) {
        registrar = _registrar;
        resolver = _resolver;
        ens = _ens;
        photochromicSignerAddress = _sigAddr;
        pricePerYear = 0.01 ether;
    }

    function upgradeResolver(address newResolver) external onlyOwner {
        require(newResolver != address(0));
        resolver = PhotochromicResolver(newResolver);
    }

    function setTicketValidity(uint256 newTicketValidity) external onlyOwner {
        ticketValidity = newTicketValidity;
    }

    function setGracePeriod(uint256 newGracePeriod) external onlyOwner {
        gracePeriod = newGracePeriod;
    }

    function setPricePerYear(uint256 newPricePerYear) external onlyOwner {
        pricePerYear = newPricePerYear;
    }

    function lastLiveness(bytes32 node) external view returns (uint32) {
        (uint32 livenessTime,) = resolver.getValidityInfo(node);
        return livenessTime;
    }

    function getValidityInfo(bytes32 node) external view returns (uint32, uint32) {
        return resolver.getValidityInfo(node);
    }

    /**
      * Updates the liveness of a userId. The given signature needs to match `photochromicSignerAddress`.
      */
    function updateLiveness(
        bytes32 node,
        uint32 livenessTime,
        EcdsaSig memory sig
    ) external payable {
        require(registrar.balanceOf(msg.sender) == 1);
        bytes32 hash = keccak256(abi.encode(msg.sender, node, livenessTime));
        address signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer == photochromicSignerAddress, "liveness signature does not match contents");
        resolver.updateLiveness(node, livenessTime);
    }

    /**
      * Renews the expiry of a userId.
      */
    function renew(bytes32 node, uint256 yrs) external payable {
        uint256 price = pricePerYear * yrs;
        require(price <= msg.value, "insufficient amount paid");
        resolver.updateExpiry(node, uint32(365 days * yrs));
    }


    function updateSignerAddress(address newPhotochromicSignerAddress) external onlyOwner {
        photochromicSignerAddress = newPhotochromicSignerAddress;
    }

    function encodeDomainInfo(
        // The time of the ticket purchase.
        uint256 purchaseTime,
        // The amount of years (expiry).
        uint256 yrs,
        // The profile for which the user payed for.
        uint8 profileNum,
        // The user identifier to register.
        string memory userId
    ) internal pure returns (bytes memory) {
        // [purchaseTime, years, profile, userId]
        return abi.encodePacked(
            uint32(purchaseTime),
            uint8(yrs),
            uint8(profileNum),
            userId
        );
    }

    function getProfileNum(string memory profile) internal view returns (uint256) {
        for (uint256 p = 0; p < profiles.length; p++) {
            if (keccak256(bytes(profiles[p].name)) == keccak256 (bytes(profile))) {
                return p;
            }
        }
        revert("unknown profile");
    }

    function decodeDomainInfo(bytes memory bs) internal pure returns (DomainInfo memory) {
        DomainInfo memory domainInfo = DomainInfo("",0,0,0);
        if (bs.length < 7) return domainInfo;

        domainInfo.purchaseTime = (uint32(uint8(bs[0])) << 24) | (uint32(uint8(bs[1])) << 16)
                                | (uint32(uint8(bs[2])) << 8)  |  uint32(uint8(bs[3]));
        domainInfo.yrs = uint8(bs[4]);
        domainInfo.profileNum = uint8(bs[5]);
        bytes memory userId = new bytes(bs.length - 6);
        for (uint256 i = 6; i < bs.length; i++) {
            userId[i - 6] = bs[i];
        }
        domainInfo.userId = string(userId);
        return domainInfo;
    }

    /**
     * Returns the list of profile names.
     */
    function getProfileNames() external view returns (string[] memory) {
        string[] memory profileNames = new string[](profiles.length);
        for (uint i=0; i < profiles.length; i++) {
            profileNames[i] = profiles[i].name;
        }
        return profileNames;
    }

    /**
     * Returns the price in ETH.
     */
    function getPrice(string calldata profile, uint256 yrs) public view returns (uint256) {
        require(0 < yrs, "years < 1");
        uint128 basePrice = profiles[getProfileNum(profile)].price;
        return basePrice + pricePerYear * (yrs - 1);
    }

    /**
     * Returns the amount of socials allowed to mint.
     */
    function getSocialsAmount(string calldata profile) external view returns (uint256) {
        return profiles[getProfileNum(profile)].info & 0xf; // lowest 4 bits
    }

    /**
     * Overwrites all the profiles.
     */
    function setProfiles(Profile[] calldata newProfiles) external onlyOwner {
        require(newProfiles.length != 0);
        delete profiles;
        for (uint i = 0; i < newProfiles.length; i++) {
            profiles.push(Profile({name: newProfiles[i].name, price:newProfiles[i].price, info: newProfiles[i].info}));
        }
    }

    function purchase(
        string memory userId,
        string calldata profile,
        uint256 yrs
    ) external payable {
        require(bytes(userId).length > 0);

        uint256 price = getPrice(profile, yrs);
        require(price <= msg.value, "insufficient amount paid");

        // If the baseNode is not the same as the registrar's baseNode then the node should
        // be owned by the sender.
        (string memory label, bytes32 baseNode) = PhotochromicTools.decomposeEns(userId);
        bytes32 node = PhotochromicTools.namehash(baseNode, label);
        if (!registrar.isBaseNode(baseNode)) {
            // The sender needs to be the owner of the node if it is not a
            // PhotoChromic identity.
            require(ens.owner(node) == msg.sender);
        }

        // Check whether someone already owns a ticket for this userId.
        address addressOwningUserId = nodeToAddress[node];
        if (addressOwningUserId != address(0)) {
            DomainInfo memory existingDomainInfo = decodeDomainInfo(addressToDomainInfo[addressOwningUserId]);
            // The sender of purchase is not the owner of the ticket, so we check whether the existing ticket is still
            // valid. If so, revert. The sender can not buy a ticket for the given userId.
            if (addressOwningUserId != msg.sender) {
                require(
                    existingDomainInfo.purchaseTime + ticketValidity < block.timestamp,
                    "a ticket was already purchased for this user id and has not yet expired"
                );
            }
            // The sender owns the ticket or the ticket expired.
            _burnTicket(node, addressOwningUserId);
        }

        // In case there is no (valid) ticket, someone else could still have registered the userId.
        (, uint32 expiryTime) = resolver.getValidityInfo(node);
        if (expiryTime != 0) {
            // Someone owns the user id already, check whether it expired.
            require(
                expiryTime + gracePeriod < block.timestamp,
                "this userId was already minted but is still valid/in its grace period"
            );

            // The node expired and is not within the grace period.
            _burn(node, baseNode, PhotochromicTools.labelhash(label), ens.owner(node));
        }

        // Check whether the user already owns a valid ticket for a userId (any, can be different from this one).
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[msg.sender]);
        if (bytes(domainInfo.userId).length != 0) {
            require(
                domainInfo.purchaseTime + ticketValidity < block.timestamp,
                "a ticket was purchased for the userId and is not yet expired"
            );

            _burnTicket(node, msg.sender);
        }

        // Create a new ticket for the given userId.
        nodeToAddress[node] = msg.sender;
        uint32 currentTime = uint32(block.timestamp);
        addressToDomainInfo[msg.sender] = encodeDomainInfo(currentTime, yrs, uint8(getProfileNum(profile)), userId);
        emit Ticket(msg.sender, node, userId, profile, yrs, currentTime);
    }

    // Checks whether the given node is still available.
    // 1. There is no (valid) ticket for this node.
    // 2. The node is not yet registered or in its grace period.
    function available(bytes32 node) external view returns (bool) {
        // (1)
        address addresOwningUserId = nodeToAddress[node];
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[addresOwningUserId]);
        if (block.timestamp < domainInfo.purchaseTime + ticketValidity) {
            // The ticket is still valid.
            return false;
        }

        // (2)
        (, uint32 expiryTime) = resolver.getValidityInfo(node);
        if (block.timestamp < expiryTime + gracePeriod) {
            // The ticket is not expired/in its grace period.
            return false;
        }

        // The given user id is available for purchase.
        return true;
    }

    // Checks whether there is a valid userId ticket for the given requester.
    // 1. The requester != 0x00.
    // 2. There is a ticket owned by the requester.
    // 3. The ticket is still valid.
    function isValidTicket(bytes32 node, address requester) external view returns (bool) {
        address addresOwningUserId = nodeToAddress[node];
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[addresOwningUserId]);
        return requester != address(0) && addresOwningUserId == requester && block.timestamp <= domainInfo.purchaseTime + ticketValidity;
    }

    /**
     * Removes the ticket for the given node.
     */
    function burnTicket(bytes32 node) external {
        address userAddress = nodeToAddress[node];
        require(msg.sender == userAddress || msg.sender == owner());
        _burnTicket(node, userAddress);
    }

    function _burnTicket(bytes32 node, address holder) internal {
        delete nodeToAddress[node];
        delete addressToDomainInfo[holder];
    }

    /**
     * Burns the userId at the registrar.
     * This is limited to PhotoChromic subdomains.
     */
    function burn(string memory userId) external {
        (string memory label, bytes32 baseNode) = PhotochromicTools.decomposeEns(userId);
        bytes32 node = PhotochromicTools.namehash(baseNode, label);
        address nodeOwner = registrar.ownerOf(uint256(node));
        require(msg.sender == nodeOwner || msg.sender == owner(), "user does not own the given userId");
        bytes32 labelHash = keccak256(abi.encodePacked(label));
        _burn(node, baseNode, labelHash, nodeOwner);
    }

    function clearRecords() external {
        bytes32 node = registrar.getNode(msg.sender);
        registrar.removeNode(msg.sender);
        resolver.clearPCRecords(node);
        resolver.deleteValidityInfo(node);
    }

    function _burn(bytes32 node, bytes32 baseNode, bytes32 labelHash, address holder) internal {
        registrar.burn(labelHash, baseNode);
        registrar.removeNode(holder);
        resolver.clearPCRecords(node);
        resolver.deleteValidityInfo(node);
    }

    /**
     * Transfers out the specified amount to the owner account.
     */
    function transferBalance(uint256 amount) external onlyOwner {
        require((amount <= address(this).balance) && (amount > 0));
        address payable receiver = payable(msg.sender);
        receiver.transfer(amount);
    }

    /**
     * Transfer ownership of resolver to a new address
     */
    function setResolverOwner(address newOwner) external onlyOwner {
        resolver.transferOwnership(newOwner);
    }

    /**
     * Returns the address linked to the ticket of the given node.
     */
    function getTicketAddress(bytes32 node) external view returns (address) {
        return nodeToAddress[node];
    }

    /**
     * Returns the user identifier of the ticket linked to the given address.
     */
    function getTicketUserId(address userAddress) public view returns (string memory userId) {
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[userAddress]);
        return domainInfo.userId;
    }

    /**
     * Returns the user identifier corresponding to the sender's ticket.
     */
    function getTicketUserId() external view returns (string memory userId) {
        return getTicketUserId(msg.sender);
    }

    /**
     * Returns the profile corresponding to the ticket of the sender.
     */
    function getTicketProfile() external view returns (string memory profile, uint8 yrs) {
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[msg.sender]);
        if (bytes(domainInfo.userId).length == 0) return ("", 0);
        return (profiles[domainInfo.profileNum].name, domainInfo.yrs);
    }

    /**
     * Creates an identity if the sender has a ticket for the given userId and the signature matches
     * `photochromicSignerAddress`.
     */
    function mint(
        PhotoChromicRecord calldata data,
        ValidatedTextRecord[] calldata texts,
        ValidatedAddrRecord[] calldata addrs,
        string calldata avatar
    ) external {
        bytes32 node;
        {
            (string memory label, bytes32 baseNode) = PhotochromicTools.decomposeEns(data.userId);
            node = PhotochromicTools.namehash(baseNode, label);

            // Check ticket exists for the sender.
            require(nodeToAddress[node] == msg.sender, "need to purchase a ticket first");

            // Check the signature of the KYC data.
            require(validPhotoChromicRecord(msg.sender, data), "signature does not match contents");
            registrar.register(msg.sender, address(resolver), PhotochromicTools.labelhash(label), baseNode, data.ipfsHash);
            {
                DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[msg.sender]);
                // Check if the request did not exceed the amount of validated records.
                require(texts.length + addrs.length <= profiles[domainInfo.profileNum].info & 0xf);

                if (registrar.isBaseNode(baseNode)) {
                    emit NameRegistered(uint(node), msg.sender, uint32(domainInfo.purchaseTime + (365 days * uint32(domainInfo.yrs))));
                }

                resolver.setPCRecords(node, data.userId, data.contents, msg.sender, profiles[domainInfo.profileNum].name);
                resolver.setValidityInfo(
                    node,
                    uint32(domainInfo.purchaseTime + (365 days * uint32(domainInfo.yrs))),
                    data.livenessTime
                );
                resolver.setValidatedTextRecords(node, texts);
                resolver.setValidatedAddrRecords(node, addrs);
                if (bytes(avatar).length > 0) {
                    resolver.setText(node, "avatar", avatar);
                }
            }
        }
        // Remove ticket.
        _burnTicket(node, msg.sender);
    }

    function validPhotoChromicRecord(address sender, PhotoChromicRecord calldata data) internal view returns (bool) {
        bytes32 h = keccak256(abi.encode(sender, data.livenessTime, data.contents, data.userId, data.ipfsHash));
        address signer = ecrecover(h, data.sig.v, data.sig.r, data.sig.s);
        return signer == photochromicSignerAddress;
    }
}
