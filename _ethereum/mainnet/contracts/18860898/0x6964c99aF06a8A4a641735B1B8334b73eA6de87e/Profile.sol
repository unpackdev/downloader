// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Profile {
    address private owner;

    address super_owner;

    string private verification_status;

    bool private verified;

    string private name;

    string private description;

    bool private dev;

    string private email;

    string private age;

    string private phone_number;

    string private country;

    string private state;

    string private residential_address;

    string private profile_pic_url;

    string private identity_url;

    uint256 private reputation_score;

    uint256 private idbot_number;

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
        uint256 reputation_score;
    }

    Project[] private _projects;

    mapping (address => Project) private projects;

    mapping (address => bool) private accesslist;

    event AddProject(address indexed ca, string name);

    event Verified(address owner);

    event Unverified(address owner);

    constructor(
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
        address owner_,
        uint256 number
    ) {
        verification_status = "Pending";
        
        name = _name;

        description = _description;

        dev = _dev;

        email = _email;

        age = _age;

        phone_number = phone;

        country = _country;

        state = _state;

        residential_address = _address;

        profile_pic_url = urls[0];

        identity_url = urls[1];

        idbot_number = number;

        reputation_score = 0;

        owner = _owner;

        super_owner = owner_;

        accesslist[_owner] = true;

        accesslist[owner_] = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == super_owner, "Not Authorized.");
        _;
    }

    modifier onlySuperOwner {
        require(msg.sender == super_owner, "Not Authorized.");
        _;
    }

    function getVerificationStatus() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return verification_status;
    }

    function getOwner() public view returns (address) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return owner;
    }

    function getName() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return name;
    }

    function getDescription() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return description;
    }

    function isDev() public view returns (bool) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return dev;
    }

    function getEmail() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return email;
    }

    function getAge() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return age;
    }

    function getPhoneNumber() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return phone_number;
    }

    function getCountry() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return country;
    }

    function getState() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return state;
    }

    function getResidentialAddress() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return residential_address;
    }

    function getProfilePicUrl() public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return profile_pic_url;
    }

    function getIdentityUrl() public onlySuperOwner view returns (string memory) {
        return identity_url;
    }

    function getIDBotNumber() public view returns (uint256) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return idbot_number;
    }

    function getReputationScore() public view returns (uint256) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return reputation_score;
    }

    function getAccountAccess(address account) public view returns (bool) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return accesslist[account];
    }

    function getProjects() public view returns (Project[] memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");

        return _projects;
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
    ) public onlyOwner {
        require(verified, "Not verified.");
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

        _projects.push(project);

        projects[_contract_address] = project;
        
        reputation_score += 100;

        emit AddProject(_contract_address, _name);
    }

    function getProjectName(address ca) public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");
        Project memory project = projects[ca];

        return project.name;
    }

    function getProjectDescription(address ca) public view returns (string memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");
        Project memory project = projects[ca];

        return project.description;
    }

    function getProjectContractAddress(address ca) public view returns (address) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");
        Project memory project = projects[ca];

        return project.contract_address;
    }

    function getProjectLinks(address ca) public view returns (string[5] memory) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");
        Project memory project = projects[ca];

        string[5] memory links = [
            project.website_link,
            project.telegram_link,
            project.twitter_link,
            project.discord_link,
            project.linktree
        ];

        return links;
    }

    function checkIfProjectIsHoneyPot(address ca) public view returns (bool) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");
        Project memory project = projects[ca];

        return project.isHoneyPot;
    }

    function checkIfProjectIsRugged(address ca) public view returns (bool) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");
        Project memory project = projects[ca];

        return project.isRugged;
    }

    function getProjectReputationScore(address ca) public view returns (uint256) {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");
        Project memory project = projects[ca];

        return project.reputation_score;
    }

    function reportProjectIsHoneyPot(address ca) public {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");
        Project storage project = projects[ca];

        if(project.isHoneyPot == false) {
            project.isHoneyPot = true;
        }

        project.reputation_score -= 1;

        reputation_score -= 1;
    }

    function reportProjectIsRugged(address ca) public {
        require(accesslist[msg.sender], "You are not authorized to perform this transaction.");
        Project storage project = projects[ca];

        if(project.isRugged == false) {
            project.isRugged = true;
        }

        project.reputation_score -= 1;

        reputation_score -= 1;
    }

    function changeOwner(address _owner) public onlyOwner {
        require(verified, "Not verified.");
        owner = _owner;
    }

    function addAccountToAccessList(address account) public {
        accesslist[account] = true;
    }

    function removeAccountFromAccessList(address account) public {
        accesslist[account] = false;
    }

    function addVerification() public onlySuperOwner {
        verification_status = "Verified";
        verified = true;

        emit Verified(owner);
    }

    function removeVerification() public onlySuperOwner {
        verification_status = "Not Verified";
        verified = false;

        emit Unverified(owner);
    }
}