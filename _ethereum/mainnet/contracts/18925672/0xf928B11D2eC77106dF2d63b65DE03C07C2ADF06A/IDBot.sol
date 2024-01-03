// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract IDBot {
    address public owner;

    struct Profile {
        address user;
        uint256 idbot_number;
        string name;
        string description;
        bool dev;
        string email;
        string age;
        string phone_number;
        string country;
        string state;
        string residential_address;
        string profile_pic_url;
        string identity_url;
        int256 reputation_score;
        string verification_status;
        bool verified;
        Project[] projects;
    }

    struct Project {
        string name;
        string description;
        address contract_address;
        string chain;
        string website_link;
        string telegram_link;
        string twitter_link;
        string discord_link;
        string linktree;
        bool isHoneyPot;
        bool isRugged;
        int256 reputation_score;
    }

    struct Subscription {
        address user;
        uint256 duration;
        uint256 startedAt;
        bool isActive;
    }

    Profile[] private _profiles;

    Subscription[] public _subscribers;

    mapping (address => Profile) private profiles;

    mapping (uint256 => Profile) private profiles_;

    mapping (address => bool) public isProfiled;

    mapping (address => Subscription) public subscribers;

    mapping (address => bool) public access_list;

    event CreateProfile(address indexed user, uint256 profileId);

    event Subscribed(address indexed user, uint256 duration);

    event AddProject(address indexed contract_address, string name);

    event Verified(address indexed user);

    event Unverified(address indexed user);

    constructor() {
        owner = msg.sender;

        access_list[msg.sender] = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not Authorized.");
        _;
    }

    function getProfiles() public onlyOwner view returns (Profile[] memory) {
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
        uint256 number
    ) public {
        require(!isProfiled[msg.sender], "You already have an account.");

        uint256 profileId = number + block.timestamp;

        Project[] memory projects;

        Profile memory profile = Profile({
            user : msg.sender,
            idbot_number : profileId,
            name : _name,
            description : _description,
            dev : _dev,
            email : _email,
            age : _age,
            phone_number : phone,
            country : _country,
            state : _state,
            residential_address : _address,
            profile_pic_url : urls[0],
            identity_url : urls[1],
            reputation_score : 0,
            verification_status : "Pending",
            verified : false,
            projects : projects
        });

        _profiles.push(profile);

        profiles[msg.sender] = profile;

        profiles_[profileId] = profile;

        isProfiled[msg.sender] = true;

        emit CreateProfile(msg.sender, profileId);
    }

    function subscribe(uint256 _duration) public payable {
        if(isSubscribed(msg.sender)) {
            updateSubscription(_duration);
        } else {
            Subscription memory subscription = Subscription({
                user : msg.sender,
                duration : _duration,
                startedAt : block.timestamp,
                isActive : true
            });

            access_list[msg.sender] = true;

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

                access_list[subscriber.user] = false;
            }
        }
    }

    function isSubscribed(address _user) public view returns (bool subscribed) {
        Subscription memory subscriber = subscribers[_user];

        if(_user == subscriber.user) {
            return true;
        } else {
            return false;
        }
    }

    function updateSubscription(uint256 _duration) public payable {
        Subscription storage subscriber = subscribers[msg.sender];

        if(subscriber.isActive == false) {
            subscriber.isActive = true;

            subscriber.duration = _duration;
        } else {
            subscriber.duration += _duration;
        }

        subscriber.startedAt = block.timestamp;

        access_list[msg.sender] = true;

        emit Subscribed(msg.sender, _duration);

        (bool success, ) = payable(owner).call{value: msg.value}("");

        require(success);
    }

    function getVerificationStatus(address user) public view returns (string memory) {
        Profile storage profile = profiles[user];

        return profile.verification_status;
    }

    function getUser(uint256 idbot_number) public view returns (address) {
        Profile storage profile = profiles_[idbot_number];

        return profile.user;
    }

    function getName(address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.name;
    }

    function getDescription(address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.description;
    }

    function isDev(address user) public view returns (bool) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.dev;
    }

    function getEmail(address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.email;
    }

    function getAge(address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.age;
    }

    function getPhoneNumber(address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.phone_number;
    }

    function getCountry(address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.country;
    }

    function getState(address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.state;
    }

    function getResidentialAddress(address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.residential_address;
    }

    function getProfilePicUrl(address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.profile_pic_url;
    }

    function getIdentityUrl(address user) public onlyOwner view returns (string memory) {
        Profile storage profile = profiles[user];

        return profile.identity_url;
    }

    function getIDBotNumber(address user) public view returns (uint256) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.idbot_number;
    }

    function getReputationScore(address user) public view returns (int256) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.reputation_score;
    }

    function addProject(
        string memory _name,
        string memory _description,
        address _contract_address,
        string memory _chain,
        string memory _website_link,
        string memory _telegram_link,
        string memory _twitter_link,
        string memory _discord_link,
        string memory _linktree
    ) public {
        Profile storage profile = profiles[msg.sender];

        require(profile.verified, "Not verified.");

        Project[] storage projects = profile.projects;

        Project memory project = Project({
            name : _name,
            description : _description,
            contract_address : _contract_address,
            chain : _chain,
            website_link : _website_link,
            telegram_link : _telegram_link,
            twitter_link : _twitter_link,
            discord_link : _discord_link,
            linktree : _linktree,
            isHoneyPot : false,
            isRugged : false,
            reputation_score : 100
        });

        projects.push(project);
        
        profile.reputation_score += 100;

        emit AddProject(_contract_address, _name);
    }

    function getProjects(address user) public view returns (Project[] memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        return profile.projects;
    }

    function getProject(address ca, address user) internal view returns (Project memory project) {
        require(access_list[user], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        for (uint256 i = 0; i < profile.projects.length; i++) {
            if(profile.projects[0].contract_address == ca) {
                return profile.projects[0];
            }
        }
    }

    function getProjectName(address ca, address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");

        Project memory project = getProject(ca, user);

        return project.name;
    }

    function getProjectDescription(address ca, address user) public view returns (string memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");

        Project memory project = getProject(ca, user);

        return project.description;
    }

    function getProjectContractAddress(address ca, address user) public view returns (address) {
        require(access_list[user], "You are not authorized to perform this transaction.");

        Project memory project = getProject(ca, user);

        return project.contract_address;
    }

    function getProjectLinks(address ca, address user) public view returns (string[5] memory) {
        require(access_list[user], "You are not authorized to perform this transaction.");

        Project memory project = getProject(ca, user);

        string[5] memory links = [
            project.website_link,
            project.telegram_link,
            project.twitter_link,
            project.discord_link,
            project.linktree
        ];

        return links;
    }

    function checkIfProjectIsHoneyPot(address ca, address user) public view returns (bool) {
        require(access_list[user], "You are not authorized to perform this transaction.");

        Project memory project = getProject(ca, user);

        return project.isHoneyPot;
    }

    function checkIfProjectIsRugged(address ca, address user) public view returns (bool) {
        require(access_list[user], "You are not authorized to perform this transaction.");

        Project memory project = getProject(ca, user);

        return project.isRugged;
    }

    function getProjectReputationScore(address ca, address user) public view returns (int256) {
        require(access_list[user], "You are not authorized to perform this transaction.");

        Project memory project = getProject(ca, user);

        return project.reputation_score;
    }

    function reportProjectIsHoneyPot(address ca, address user) public {
        require(access_list[msg.sender], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        for (uint256 i = 0; i < profile.projects.length; i++) {
            if(profile.projects[0].contract_address == ca) {
                Project storage project = profile.projects[0];

                if(project.isHoneyPot == false) {
                    project.isHoneyPot = true;
                }

                project.reputation_score -= 1;

                profile.reputation_score -= 1;
            }
        }
    }

    function reportProjectIsRugged(address ca, address user) public {
        require(access_list[msg.sender], "You are not authorized to perform this transaction.");
        Profile storage profile = profiles[user];

        for (uint256 i = 0; i < profile.projects.length; i++) {
            if(profile.projects[0].contract_address == ca) {
                Project storage project = profile.projects[0];

                if(project.isRugged == false) {
                    project.isRugged = true;
                }

                project.reputation_score -= 1;

                profile.reputation_score -= 1;
            }
        }
    }

    function addVerification(address user) public onlyOwner {
        Profile storage profile = profiles[user];

        profile.verification_status = "Verified";
        profile.verified = true;

        emit Verified(user);
    }

    function removeVerification(address user) public onlyOwner {
        Profile storage profile = profiles[user];

        profile.verification_status = "Not Verified";
        profile.verified = false;

        emit Unverified(user);
    }
}