 //SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./LandNFT_Authorization.sol";

contract MossLandNFT is LandNFT_Authorization {

    enum ProjectType { GOVERNANCE, PROPERTY }

    struct Project {
        uint256 id;
        uint256 totalHectares;
        uint256 totalSupply;
        uint256 inflationCooldownPeriod;
        uint256 nextInflationAt;
        ProjectType projectType;
        bool created;
    }

    uint256 public constant HECTARE_TOKEN_INFLATION_RATE_FACTOR = 10000;

    string public name;
    string public symbol;
    string public description;

    address public owner; // for opensea
    uint256[] public tokenIds; // list of token ids - order is not important

    mapping(uint256 => Project) public projects;
    mapping (uint256 => string) private _tokenURIs;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ProjectAdded(address sender, Project project);
    event TokenInflation(uint256 tokenId, uint256 ratio, address sender);

    function initialize(
        string calldata __uri,
        string calldata _name,
        string calldata _symbol,
        string calldata _description,
        address _owner
    )
        public
        initializer
    {
        __ERC1155_init(__uri);
        __EIP712_init("LandNFT", "1");

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        name = _name;
        symbol = _symbol;
        description = _description;
        owner = _owner;

        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**************************************
     ROLE-RESTRICTED WRITE FUNCTIONS
    ***************************************/

    function addProject(
        uint256 id,
        string calldata cid,
        uint256 hectares,
        uint256 cooldown,
        ProjectType projectType
    )
        external
        onlyMinter
    {
        require(hectares > 0, "LandNFT: invalid hectares");
        require(cooldown > 0, "LandNFT: invalid cooldown period");
        require(bytes(cid).length > 0, "LandNFT: empty cid");
        require(!projects[id].created, "LandNFT: project already added");

        tokenIds.push(id);

        projects[id] = Project({
            id: id,
            totalHectares: hectares,
            totalSupply: hectares,
            inflationCooldownPeriod: cooldown,
            nextInflationAt: block.timestamp + cooldown,
            created: true,
            projectType: projectType
        });

        _mint(msg.sender, id, hectares, new bytes(0));

        _setTokenURI(id, cid);

        emit ProjectAdded(msg.sender, projects[id]);
    }

    function inflate(
        uint256 projectId,
        uint256 increase
    )
        public
        onlyMinter
    {
        Project storage project = projects[projectId];

        require(project.created, "LandNFT: project not registered");
        require(increase != 0, "LandNFT: increase ratio cannot be zero");
        require(block.timestamp > project.nextInflationAt, "LandNFT: project is in cooldown period");

        uint256 additionalAmount = project.totalSupply * increase/ HECTARE_TOKEN_INFLATION_RATE_FACTOR;

        project.totalSupply += additionalAmount;
        project.nextInflationAt += project.nextInflationAt + project.inflationCooldownPeriod;

        _mint(msg.sender, projectId, additionalAmount, new bytes(0));
        
        emit TokenInflation(projectId, additionalAmount, msg.sender);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    )
        public
        override
        onlyBurner
    {
        _burn(account, id, value);

        projects[id].totalSupply -= value;
    }

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    )
        public
        override
        onlyBurner
    {
        _burnBatch(account, ids, values);
        for (uint256 i = 0; i < ids.length; i++) {
            projects[ids[i]].totalSupply -= values[i];
        }
    }

    function updateTokenURI(
        uint256 id,
        string memory cid
     )
        external
        onlyAdmin
    {
        require(projects[id].created, "LandNFT: token not registered");

        _setTokenURI(id, cid);
    }

    /**
     * @dev Internal function to set the token cid for a given token.
     * @param tokenId uint256 ID of the token to set its URI
     * @param cid string ipfs cid to assign
     */
    function _setTokenURI(uint256 tokenId, string memory cid) internal {
        _tokenURIs[tokenId] = string(abi.encodePacked(_uri, cid));

        emit URI(_tokenURIs[tokenId], tokenId);
    }

    /**
     * @dev Updates owner
     * @param _newOwner new owner's address
     */
    function setOwner(address _newOwner)
      external
      onlyAdmin
    {
        require(_newOwner != address(0), "LandNFT: invalid owner address");

        emit OwnershipTransferred(owner, _newOwner);

        owner = _newOwner;
    }

    /**************************************
     READ FUNCTIONS
    ***************************************/

    function isRegistered(
        uint256 id
    ) external view returns (bool) {
        return projects[id].created;
    }

    function getRegisteredTokens()
        external view returns (uint256[] memory) {
        return tokenIds;
    }

    function hectaresBalanceOf(address account, uint256 id) public view returns (uint256 balance, uint256 totalSupply, uint256 totalHectares) {
        balance = super.balanceOf(account, id);
        totalSupply = projects[id].totalSupply;
        totalHectares = projects[id].totalHectares;
    }

    function balancesOf(
        address wallet
    ) external view returns (uint256[] memory tokens, uint256[] memory balances) {
        tokens = tokenIds;
        balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            balances[i] = balanceOf(wallet, tokens[i]);
        }
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return _tokenURI(_id);
    }

    /**
     * @dev Returns an URI for a given token ID. If tokenId is 0, returns _uri
     * @param tokenId uint256 ID of the token to query
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        if (tokenId == 0) return _uri;

        return _tokenURIs[tokenId];
    }

}
