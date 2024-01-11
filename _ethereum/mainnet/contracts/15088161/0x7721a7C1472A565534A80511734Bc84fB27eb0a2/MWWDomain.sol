// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./Ownable.sol";

library MWWStructs {
    struct Domain {
        address owner;
        uint256 planId;
        uint256 expiryTime; //valid until when
        string domain;
        string configIpfsHash;
        uint256 registeredAt;
    }
}

contract MWWDomain is Ownable {
    mapping(address => bool) private admins;
    mapping(string => MWWStructs.Domain) public domains;
    mapping(address => string[]) private accountDomains;
    mapping(string => address[]) private domainDelegates;

    address public registerContract;

    event MWWSubscribed(
        address indexed subscriber,
        uint256 planId,
        uint256 expiryTime,
        string domain
    );
    event MWWDomainChanged(
        address indexed subscriber,
        string originalDomain,
        string newDomain
    );

    constructor(address _registar) {
        admins[msg.sender] = true;
        registerContract = _registar;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can do it");
        _;
    }

    modifier onlyRegisterContract() {
        require(
            msg.sender == registerContract,
            "Only the register can call this"
        );
        _;
    }

    function setRegisterContract(address _address) public onlyOwner {
        registerContract = _address;
    }

    function removeAdmin(address admin) public onlyOwner {
        admins[admin] = false;
    }

    function addAdmin(address admin) public onlyAdmin {
        admins[admin] = true;
    }

    function isDelegate(string calldata domain) public view returns (bool) {
        address[] memory delegates = domainDelegates[domain];

        for (uint256 i = 0; i < delegates.length; i++) {
            if (delegates[i] == msg.sender) {
                return true;
            }
        }

        return false;
    }

    function isAllowedToManageDomain(string calldata domain)
        private
        view
        returns (bool)
    {
        return isDelegate(domain) || domains[domain].owner == msg.sender;
    }

    function addDelegate(string calldata domain, address delegate) public {
        require(
            domains[domain].owner == msg.sender,
            "You are not allowed to do this"
        );
        domainDelegates[domain].push(delegate);
    }

    function removeDelegate(string calldata domain, address delegate) public {
        require(
            domains[domain].owner == msg.sender,
            "You are not allowed to do this"
        );

        uint256 j = 0;
        uint256 size = domainDelegates[domain].length;
        address[] memory auxDelegates = new address[](
            size - 1
        );
        for (uint256 i = 0; i < size; i++) {
            if (domainDelegates[domain][i] != delegate) {
                auxDelegates[j] = domainDelegates[domain][i];
                j = j + 1;
            }
        }
        domainDelegates[domain] = auxDelegates;
    }

    function subscribe(
        address originalCaller,
        uint256 planId,
        address planOwner,
        uint256 duration,
        string calldata domain,
        string calldata ipfsHash
    ) public onlyRegisterContract returns (MWWStructs.Domain memory) {
        return
            _subscribe(
                originalCaller,
                planId,
                planOwner,
                duration,
                domain,
                ipfsHash
            );
    }

    function addDomains(
        MWWStructs.Domain[] calldata domainsToAdd
    ) public onlyAdmin returns (bool) {
            uint256 size = domainsToAdd.length;
        for (uint256 i = 0; i < size; i++) {
            MWWStructs.Domain calldata domain = domainsToAdd[i];
            _subscribe(
                address(0),
                domain.planId,
                domain.owner,
                domain.expiryTime - block.timestamp,
                domain.domain,
                domain.configIpfsHash
            );
        }
        return true;
    }

    function _subscribe(
        address originalCaller,
        uint256 planId,
        address planOwner,
        uint256 duration,
        string calldata domain,
        string calldata ipfsHash
    ) private returns (MWWStructs.Domain memory) {
        if (
            domains[domain].owner != address(0) &&
            domains[domain].expiryTime > block.timestamp
        ) {
            // check subscription exists and is not expired
            require(
                domains[domain].owner == planOwner,
                "Domain registered for someone else"
            );
            require(
                domains[domain].planId == planId,
                "Domain registered with another plan"
            );

            MWWStructs.Domain storage existingDomain = domains[domain];
            existingDomain.expiryTime = existingDomain.expiryTime + duration;

            return existingDomain;
        }

        MWWStructs.Domain memory _domain = MWWStructs.Domain({
            owner: planOwner,
            planId: planId,
            expiryTime: block.timestamp + duration,
            domain: domain,
            configIpfsHash: ipfsHash,
            registeredAt: block.timestamp
        });

        if (originalCaller != address(0) && planOwner != originalCaller) {
            domainDelegates[domain].push(originalCaller);
        }

        domains[domain] = _domain;

        accountDomains[planOwner].push(domain);

        emit MWWSubscribed(planOwner, planId, duration, domain);

        return _domain;
    }

    function changeDomain(string calldata domain, string calldata newDomain)
        public
        returns (MWWStructs.Domain memory)
    {
        require(
            isAllowedToManageDomain(domain),
            "Only the owner or delegates can manage the domain"
        );
        require(isSubscriptionActive(domain), "Subscription expired");
        require(
            !isSubscriptionActive(newDomain),
            "New Domain must be unregistered or expired."
        );

        MWWStructs.Domain memory subs = domains[domain];

        domains[newDomain] = MWWStructs.Domain({
            owner: subs.owner,
            planId: subs.planId,
            expiryTime: subs.expiryTime,
            domain: newDomain,
            configIpfsHash: subs.configIpfsHash,
            registeredAt: subs.registeredAt
        });

        delete domains[domain];

        string[] memory auxDomains = new string[](
            accountDomains[subs.owner].length
        );
        auxDomains[0] = newDomain;

        uint256 j = 1;
        bytes32 oldDomainHash = keccak256(bytes(domain));

        // TODO: same pattern can be used here (Check removePlan function comments in RegistarBase contract)
        for (uint256 i = 0; i < accountDomains[subs.owner].length; i++) {
            if (
                keccak256(bytes(accountDomains[subs.owner][i])) != oldDomainHash
            ) {
                auxDomains[j] = accountDomains[subs.owner][i];
                j++;
            }
        }

        accountDomains[subs.owner] = auxDomains;

        emit MWWDomainChanged(subs.owner, domain, newDomain);

        return domains[newDomain];
    }

    function changeDomainConfigHash(
        string calldata domain,
        string calldata ipfsHash
    ) public {
        require(
            isAllowedToManageDomain(domain),
            "Only the owner or delegates can manage the domain"
        );
        domains[domain].configIpfsHash = ipfsHash;
    }

    function isSubscriptionActive(string calldata domain)
        public
        view
        returns (bool)
    {
        return domains[domain].expiryTime > block.timestamp;
    }

    function getDomainsForAccount(address account)
        public
        view
        returns (string[] memory)
    {
        return accountDomains[account];
    }

    function getDelegatesForDomain(string memory domain)
        public
        view
        returns (address[] memory)
    {
        return domainDelegates[domain];
    }
}
