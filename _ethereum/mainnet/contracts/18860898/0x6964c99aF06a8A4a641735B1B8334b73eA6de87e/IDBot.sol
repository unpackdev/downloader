// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Profile.sol";

contract IDBot {
    address public owner;

    address[] public _profiles;

    mapping (address => address) public profiles;

    mapping (uint256 => address) public profiles_;

    mapping (address => bool) public isProfiled;

    struct Subscription {
        address account;
        uint256 duration;
        uint256 startedAt;
        bool isActive;
    }

    Subscription[] public _subscribers;

    mapping (address => Subscription) public subscribers;

    event Subscribed(address indexed account, uint256 duration);

    event CreateProfile(address indexed profile, address indexed owner, uint256 profileId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not Authorized.");
        _;
    }

    function getProfiles() public onlyOwner view returns (address[] memory) {
        return _profiles;
    }

    function createProfile(
        string memory _name,
        string memory _description,
        bool _dev,
        string memory _email,
        string memory _age,
        string memory phone,
        string memory _country,
        string memory _state,
        string memory _address,
        string[] memory urls,
        address _owner,
        uint256 number
    ) public {
        require(!isProfiled[_owner], "You already have an account.");

        uint256 profileId = number + block.timestamp;

        Profile profile = new Profile(
            _name,
            _description,
            _dev,
            _email,
            _age,
            phone,
            _country,
            _state,
            _address,
            urls,
            _owner,
            owner,
            profileId
        );

        _profiles.push(address(profile));

        profiles[_owner] = address(profile);

        profiles_[profileId] = address(profile);

        isProfiled[_owner] = true;

        emit CreateProfile(address(profile), _owner, profileId);
    }

    function subscribe(uint256 _duration) public payable {
        if(isSubscribed(msg.sender)) {
            updateSubscription(_duration);
        } else {
            Subscription memory subscription = Subscription({
                account : msg.sender,
                duration : _duration,
                startedAt : block.timestamp,
                isActive : true
            });

            for (uint i = 0; i < _profiles.length; i++) {
                Profile profile = Profile(_profiles[i]);

                profile.addAccountToAccessList(msg.sender);
            }

            _subscribers.push(subscription);

            subscribers[msg.sender] = subscription;

            emit Subscribed(msg.sender, _duration);

            (bool success, ) = payable(owner).call{value: msg.value}("");

            require(success);
        }
    }

    function unsubscribe() public onlyOwner {
        for (uint i = 0; i < _subscribers.length; i++) {
            Subscription storage subscriber = _subscribers[i];
            uint256 timeElapsed = (block.timestamp - subscriber.startedAt) / 86400;

            if(timeElapsed >= subscriber.duration && subscriber.isActive == true) {
                subscriber.isActive = false;

                for (uint x = 0; x < _profiles.length; x++) {
                    Profile profile = Profile(_profiles[x]);

                    profile.removeAccountFromAccessList(subscriber.account);
                }
            }
        }
    }

    function isSubscribed(address _account) public view returns (bool subscribed) {
        Subscription memory subscriber = subscribers[_account];

        if(_account == subscriber.account) {
            return true;
        } else {
            return false;
        }
    }

    function updateSubscription(uint256 _duration) public payable {
        Subscription storage subscriber = subscribers[msg.sender];

        if(subscriber.isActive == false) {
            subscriber.isActive = true;
        }

        subscriber.duration = _duration;

        subscriber.startedAt = block.timestamp;

        emit Subscribed(msg.sender, _duration);

        (bool success, ) = payable(owner).call{value: msg.value}("");

        require(success);
    }
}