// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TLDCreate is Ownable {
    /** STRUCTS */
    struct DomainDetails {
        string name;
        bytes12 topLevel;
        address owner;
        string ip;
    }

    /** STATE VARIABLES */
    mapping(bytes32 => DomainDetails) public domainNames;
    mapping(bytes32 => bool) public domainAvailable;

    /**
     * MODIFIERS
     */

    modifier isDomainOwner(string memory domain, bytes12 topLevel) {
        bytes32 domainHash = getDomainHash(domain, topLevel);
        require(
            domainNames[domainHash].owner == msg.sender,
            "You are not the owner of this domain."
        );
        _;
    }

    /**
     *  EVENTS
     */
    event LogDomainNameRegistered(
        uint indexed timestamp,
        string domainName,
        bytes12 topLevel
    );

    event LogDomainNameEdited(
        uint indexed timestamp,
        string domainName,
        bytes12 topLevel,
        string newIp
    );

    event LogDomainNameTransferred(
        uint indexed timestamp,
        string domainName,
        bytes12 topLevel,
        address indexed owner,
        address newOwner
    );

    /**
     * @dev - Constructor of the contract
     */
    constructor() {}

    /*
     * @dev - function to register domain name
     * @param domain - domain name to be registered
     * @param topLevel - domain top level (TLD)
     * @param ip - the ip of the host
     */
    function register(
        string memory domain,
        bytes12 topLevel,
        string memory ip
    ) public onlyOwner {
        // calculate the domain hash
        bytes32 domainHash = getDomainHash(domain, topLevel);

        // check the existing TLD same as new register
        require(domainAvailable[domainHash] == false, "Exist TLD");

        // create a new domain entry with the provided fn parameters
        DomainDetails memory newDomain = DomainDetails({
            name: domain,
            topLevel: topLevel,
            owner: msg.sender,
            ip: ip
        });

        // save the domain to the storage
        domainNames[domainHash] = newDomain;

        //set the exist TLD
        domainAvailable[domainHash] = true;

        // log domain name registered
        emit LogDomainNameRegistered(block.timestamp, domain, topLevel);
    }

    /*
     * @dev - function to edit domain name
     * @param oldDomainHash - the current domain hash
     * @param domain - the domain name to be editted
     * @param topLevel - tld of the domain
     * @param newIp - the new ip for the domain
     */
    function edit(
        string memory domain,
        bytes12 topLevel,
        string memory newIp
    ) public isDomainOwner(domain, topLevel) {
        // calculate the domain hash - unique id
        bytes32 domainHash = getDomainHash(domain, topLevel);

        // update the new ip
        domainNames[domainHash].ip = newIp;

        // log change
        emit LogDomainNameEdited(block.timestamp, domain, topLevel, newIp);
    }

    /*
     * @dev - Transfer domain ownership
     * @param domain - name of the domain
     * @param topLevel - tld of the domain
     * @param newOwner - address of the new owner
     */
    function transferDomain(
        string memory domain,
        bytes12 topLevel,
        address newOwner
    ) public isDomainOwner(domain, topLevel) {
        // prevent assigning domain ownership to the 0x0 address
        require(newOwner != address(0));

        // calculate the hash of the current domain
        bytes32 domainHash = getDomainHash(domain, topLevel);

        // assign the new owner of the domain
        domainNames[domainHash].owner = newOwner;

        // log the transfer of ownership
        emit LogDomainNameTransferred(
            block.timestamp,
            domain,
            topLevel,
            msg.sender,
            newOwner
        );
    }

    /*
     * @dev - Get ip of domain
     * @param domain
     * @param topLevel
     */
    function getIP(
        string memory domain,
        bytes12 topLevel
    ) public view returns (string memory) {
        // calculate the hash of the domain
        bytes32 domainHash = getDomainHash(domain, topLevel);

        // return the ip property of the domain from storage
        return domainNames[domainHash].ip;
    }

    /*
     * @dev - Get (domain name + top level) hash used for unique identifier
     * @param domain
     * @param topLevel
     * @return domainHash
     */
    function getDomainHash(
        string memory domain,
        bytes12 topLevel
    ) public pure returns (bytes32) {
        // @dev - tightly pack parameters in struct for keccak256
        return keccak256(abi.encodePacked(domain, topLevel));
    }
}