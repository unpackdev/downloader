// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";
import "./ERC20.sol";
import "./PriceConsumer.sol";

contract RegCenter is IRegCenter, ERC20("ComBooxPoints", "CBP"), PriceConsumer {
    using DocsRepo for DocsRepo.Repo;
    using DocsRepo for DocsRepo.Head;
    using UsersRepo for UsersRepo.Repo;
    using UsersRepo for uint256;
    
    UsersRepo.Repo private _users;
    DocsRepo.Repo private _docs;
    
    constructor() {
        _users.regUser(msg.sender);
    }

    // ########################
    // ##    Opts Setting    ##
    // ########################

    function setPlatformRule(bytes32 snOfRule) external {
        _users.setPlatformRule(snOfRule, msg.sender);
        emit SetPlatformRule(snOfRule);
    }

    function setFeedRegistry(address registry_ ) external {
        require(msg.sender == _users.getBookeeper(), "RC: not bookeeper");
        _setFeedRegistry(registry_);
        emit SetFeedRegistry(registry_);
    }

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external {
        _users.transferOwnership(newOwner, msg.sender);
        emit TransferOwnership(newOwner);
    }

    function handoverCenterKey(address newKeeper) external {
        _users.handoverCenterKey(newKeeper, msg.sender);
        emit TurnOverCenterKey(newKeeper);
    }

    // ##################
    // ##  Mint & Lock ##
    // ##################

    function mint(uint256 to, uint amt) external {

        require(msg.sender == _users.getOwner(), 
            "RC.mintPoints: not owner");

        require(to > 0, "RC.mintPoints: zero to");
        
        _mint(_users.users[to].primeKey.pubKey, amt);
    }

    function mintAndLockPoints(
        uint to, 
        uint amtOfGLee, 
        uint expireDate, 
        bytes32 hashLock
    ) external {   
        LockersRepo.Head memory head = 
            _users.mintAndLockPoints(
                to, 
                amtOfGLee, 
                expireDate, 
                hashLock, 
                msg.sender
            );
        emit LockPoints( LockersRepo.codifyHead(head), hashLock);
    }

    function lockPoints(
        uint to, 
        uint amtOfGLee, 
        uint expireDate, 
        bytes32 hashLock
    ) external {

        LockersRepo.Head memory head = 
            _users.lockPoints(
                to, 
                amtOfGLee, 
                expireDate, 
                hashLock, 
                msg.sender
            );

        emit LockPoints(LockersRepo.codifyHead(head), hashLock);

        _burn(_users.getUser(msg.sender).primeKey.pubKey, amtOfGLee * 10 ** 9);
    }

    function lockConsideration(
        uint to, 
        uint amtOfGLee, 
        uint expireDate, 
        address counterLocker, 
        bytes calldata payload, 
        bytes32 hashLock
    ) external {

        LockersRepo.Head memory head =
            _users.lockConsideration(
                to, 
                amtOfGLee, 
                expireDate, 
                counterLocker, 
                payload, 
                hashLock, 
                msg.sender
            );

        emit LockConsideration(LockersRepo.codifyHead(head), counterLocker, payload, hashLock);

        _burn(_users.getUser(msg.sender).primeKey.pubKey, amtOfGLee * 10 ** 9);
    }

    function pickupPoints(bytes32 hashLock, string memory hashKey) external
    {
        LockersRepo.Head memory head = 
            _users.pickupPoints(hashLock, hashKey, msg.sender);

        if (head.value > 0) {
            emit PickupPoints(LockersRepo.codifyHead(head));            
            _mint(_users.users[head.to].primeKey.pubKey, head.value * 10 ** 9);
        }
    }

    function withdrawPoints(bytes32 hashLock) external
    {
        LockersRepo.Head memory head = 
            _users.withdrawDeposit(hashLock, msg.sender);

        if (head.value > 0) {
            emit WithdrawPoints(LockersRepo.codifyHead(head));
            _mint(_users.users[head.from].primeKey.pubKey, head.value * 10 ** 9);
        }
    }

    function getLocker(bytes32 hashLock) external
        view returns (LockersRepo.Locker memory locker)
    {
        locker = _users.getLocker(hashLock);
    }

    function getLocksList() external 
        view returns (bytes32[] memory)
    {
        return _users.getLocksList();
    }

    // ################
    // ##    Users   ##
    // ################

    function regUser() external {
        UsersRepo.User memory user = _users.regUser(msg.sender);
        if (user.primeKey.gift > 0) {
            _mint(user.primeKey.pubKey, uint(user.primeKey.gift) * 10 ** 9);
        }
    }

    function setBackupKey(address bKey) external {
        _users.setBackupKey(bKey, msg.sender);
    }

    function upgradeBackupToPrime() external {
        _users.upgradeBackupToPrime(msg.sender);
    }

    function setRoyaltyRule(bytes32 snOfRoyalty) external {
        _users.setRoyaltyRule(snOfRoyalty, msg.sender);
    }

    // ###############
    // ##    Docs   ##
    // ###############

    function setTemplate(uint typeOfDoc, address body, uint author) external {
        require(msg.sender == getBookeeper(), 
            "RC.setTemplate: not bookeeper");
        
        DocsRepo.Head memory head = 
            _docs.setTemplate(typeOfDoc, body, author, _users.getUserNo(msg.sender));

        emit SetTemplate(head.typeOfDoc, head.version, body);
    }

    function transferIPR(uint typeOfDoc, uint version, uint transferee) external {
        _docs.transferIPR(typeOfDoc, version, transferee, _users.getUserNo(msg.sender));

        emit TransferIPR(typeOfDoc, version, transferee);
    }

    function createDoc(
        bytes32 snOfDoc,
        address primeKeyOfOwner
    ) public returns(DocsRepo.Doc memory doc)
    {
        doc = _docs.createDoc(snOfDoc, _users.getUserNo(primeKeyOfOwner));
        emit CreateDoc(doc.head.codifyHead(), doc.body);
    }

    // #########################
    // ## Comp Deploy Scripts ##
    // #########################

    function createComp(address dk) external 
    {
        address primeKeyOfOwner = msg.sender;
        address rc = address(this);
        
        address gk = _createDocAtLatestVersion(20, primeKeyOfOwner);
        IAccessControl(gk).init(primeKeyOfOwner, rc, rc, gk);
        IGeneralKeeper(gk).createCorpSeal();

        address[11] memory keepers = 
            _deployKeepers(primeKeyOfOwner, dk, rc, gk);

        _deployBooks(keepers, primeKeyOfOwner, rc, gk);
    
        IAccessControl(gk).setDirectKeeper(dk);
    }

    function _deployKeepers(
        address primeKeyOfOwner, 
        address dk,
        address rc,
        address gk
    ) private returns (address[11] memory keepers) {
        keepers[0] = dk;
        uint i = 1;
        while (i < 11) {
            keepers[i] = _createDocAtLatestVersion(i, primeKeyOfOwner);
            IAccessControl(keepers[i]).init(primeKeyOfOwner, gk, rc, gk);
            IGeneralKeeper(gk).regKeeper(i, keepers[i]);
            i++;
        }
    }

    function _deployBooks(
        address[11] memory keepers,
        address primeKeyOfOwner, 
        address rc,
        address gk
    ) private {
        address[10] memory books;
        uint8[10] memory types = [11, 12, 13, 14, 13, 15, 16, 17, 18, 19];
        uint8[10] memory seqOfDK = [1, 2, 3, 0, 5, 6, 7, 8, 0, 10];

        uint i;
        while (i < 10) {
            books[i] = _createDocAtLatestVersion(types[i], primeKeyOfOwner);
            IAccessControl(books[i]).init(primeKeyOfOwner, keepers[seqOfDK[i]], rc, gk);
            IGeneralKeeper(gk).regBook(i+1, books[i]);
            i++;
        }
    }

    function _createDocAtLatestVersion(uint256 typeOfDoc, address primeKeyOfOwner) internal
        returns(address body)
    {
        uint256 latest = _docs.counterOfVersions(typeOfDoc);
        bytes32 snOfDoc = bytes32((typeOfDoc << 224) + uint224(latest << 192));
        body = createDoc(snOfDoc, primeKeyOfOwner).body;
    }

    // ##############
    // ## Read I/O ##
    // ##############

    // ==== options ====

    function getOwner() public view returns (address) {
        return _users.getOwner();
    }

    function getBookeeper() public view returns (address) {
        return _users.getBookeeper();
    }

    function getPlatformRule() external view returns(UsersRepo.Rule memory) {
        return _users.getPlatformRule();
    }

    // ==== Users ====

    function isKey(address key) external view returns (bool) {
        return _users.isKey(key);
    }

    function counterOfUsers() external view returns(uint40) {
        return _users.counterOfUsers();
    }

    function getUser() external view returns (UsersRepo.User memory)
    {
        return _users.getUser(msg.sender);
    }

    function getRoyaltyRule(uint author)external view returns (UsersRepo.Key memory) {
        return _users.getRoyaltyRule(author);
    }

    function getUserNo(address targetAddr, uint fee, uint author) external returns (uint40) {

        uint40 target = _users.getUserNo(targetAddr);

        if (msg.sender != targetAddr && author > 0) {

            require(_docs.docExist(msg.sender), 
                "RC.getUserNo: msgSender not registered ");
            
            UsersRepo.Key memory rr = _users.getRoyaltyRule(author);
            address authorAddr = _users.users[author].primeKey.pubKey; 

            _chargeFee(targetAddr, fee, authorAddr, rr);

            // if (tx.origin != targetAddr) 
            //     _chargeFee(tx.origin, fee, authorAddr, rr);
        }

        return target;
    }

    function _chargeFee(
        address targetAddr, 
        uint fee, 
        address authorAddr,
        UsersRepo.Key memory rr    
    ) private {

        UsersRepo.User storage t = _users.users[_users.getUserNo(targetAddr)];
        address ownerAddr = _users.getOwner();

        UsersRepo.Rule memory pr = _users.getPlatformRule();
        
        // uint40 fee = uint40(fee);

        uint floorPrice = uint(pr.floor) * 10 ** 9;

        require(fee >= floorPrice, "RC.chargeFee: lower than floor");

        uint offAmt = uint(t.primeKey.coupon) * uint(rr.discount) * fee / 10000 + uint(rr.coupon) * 10 ** 9;
        
        fee = (offAmt < (fee - floorPrice))
            ? (fee - offAmt)
            : floorPrice;

        uint giftAmt = uint(rr.gift) * 10 ** 9;

        if (ownerAddr == authorAddr || pr.rate == 2000) {
            if (fee > giftAmt)
                _transfer(t.primeKey.pubKey, authorAddr, fee - giftAmt);
        } else {
            _transfer(t.primeKey.pubKey, ownerAddr, fee * (2000 - pr.rate) / 10000);
            
            uint balaceAmt = fee * (8000 + pr.rate) / 10000;
            if ( balaceAmt > giftAmt)
                _transfer(t.primeKey.pubKey, authorAddr, balaceAmt - giftAmt);
        }

        t.primeKey.coupon++;
    }

    function getMyUserNo() external view returns(uint40) {
        return _users.getUserNo(msg.sender);
    }

    // ==== Docs ====

    function counterOfTypes() external view returns(uint32) {
        return _docs.counterOfTypes();
    }

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint32) {
        return _docs.counterOfVersions(uint32(typeOfDoc));
    }

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64) {
        return _docs.counterOfDocs(uint32(typeOfDoc), uint32(version));
    }

    function docExist(address body) public view returns(bool) {
        return _docs.docExist(body);
    }

    function getAuthor(uint typeOfDoc, uint version) external view returns(uint40) {
        return _docs.getAuthor(typeOfDoc, version);
    }

    function getAuthorByBody(address body) external view returns(uint40) {
        return _docs.getAuthorByBody(body);
    }

    function getHeadByBody(address body) public view returns (DocsRepo.Head memory ) {
        return _docs.getHeadByBody(body);
    }

    function getDoc(bytes32 snOfDoc) external view returns(DocsRepo.Doc memory doc) {
        doc = _docs.getDoc(snOfDoc);
    }

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc) {
        if (_users.counterOfUsers() >= acct) { 
            doc.body = _users.users[acct].primeKey.pubKey;
            if (_docs.docExist(doc.body)) doc.head = _docs.heads[doc.body];
            else doc.body = address(0);
        }
    }

    function verifyDoc(bytes32 snOfDoc) external view returns(bool flag) {
        flag = _docs.verifyDoc(snOfDoc);
    }

    function getVersionsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getVersionsList(uint32(typeOfDoc));
    }

    function getDocsList(bytes32 snOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getDocsList(snOfDoc);
    } 

}
