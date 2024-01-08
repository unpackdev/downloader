pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "./IERC20.sol";

contract MIsForMetaverseUpgradeable is ERC721PresetMinterPauserAutoIdUpgradeable {

    address public RNDRTokenAddress;
    address public GenesisTokenAddress;
    address[] public addressesNotInCirculatingSupply;

    struct MIsForMetaverse{
        address stakingWallet;
        uint256 genesisTokenBurnBlock;
        uint256 genesisTokenBurnUnixTimestamp;
        uint256 genesisTokenStakingBalance;
        uint256 genesisTokenStakingBlock;
        uint256 genesisTokenStakingPower;
        uint256 genesisTokenStakingUnixTimestamp;
        uint256 rndrTokenBalance;
        uint256 rndrTokenStakingBlock;
        uint256 rndrTokenStakingPower;
        uint256 rndrTokenStakingUnixTimestamp;
        uint256 wikidataQID;
        uint256 wikidataQID_parent;
    }

    mapping (uint256 => MIsForMetaverse) public tokenIDtoMIsForMetaverse;
    mapping (uint256 => bool) public tokenIDHasProof;
    mapping (uint256 => string) private _tokenURIs;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Minter: caller does not have the the minter role");
        _;
    }

    constructor() {

    }

    function __MIsForMetaverseUpgradeable_init(string memory name, string memory symbol, string memory baseTokenURI, address _RNDRTokenAddress, address _genesisTokenAddress) initializer public {
         GenesisTokenAddress = _genesisTokenAddress;
         RNDRTokenAddress = _RNDRTokenAddress;
        __ERC721PresetMinterPauserAutoId_init(name,symbol,baseTokenURI);
    }

    function mint(address _to, uint256 _tokenId, uint256[2] calldata _wikidataQIDs, string memory _metadataUri, uint256 _genesisTokenBurnBlock, uint256 _genesisTokenBurnUnixTimestamp, uint256 _genesisTokenStakingBlockNumber, uint256 _genesisTokenStakingPower, uint256 _genesisTokenStakingUnixTimestamp, uint256 _rndrTokenStakingBlock, uint256 _rndrTokenStakingPower, uint256 _rndrTokenStakingUnixTimestamp) onlyMinter public {
        require(tokenIDHasProof[_tokenId] == false, "Token ID has already been minted.");

        // Create Struct to Store
        MIsForMetaverse memory m;

        m.stakingWallet = _to;
        m.genesisTokenBurnBlock = _genesisTokenBurnBlock;
        m.genesisTokenBurnUnixTimestamp = _genesisTokenBurnUnixTimestamp;
        m.genesisTokenStakingBalance = _genesisTokenStakingPower;
        m.genesisTokenStakingBlock = _genesisTokenStakingBlockNumber;
        m.genesisTokenStakingPower = _genesisTokenStakingPower;
        m.genesisTokenStakingUnixTimestamp = _genesisTokenStakingUnixTimestamp;
        m.rndrTokenBalance = readCurrentRndrBalance(_to);
        m.rndrTokenStakingBlock = _rndrTokenStakingBlock;
        m.rndrTokenStakingPower = _rndrTokenStakingPower;
        m.rndrTokenStakingUnixTimestamp = _rndrTokenStakingUnixTimestamp;
        m.wikidataQID = _wikidataQIDs[0];
        m.wikidataQID_parent = _wikidataQIDs[1];

        //Store Struct and flag as valid
        tokenIDtoMIsForMetaverse[_tokenId] = m;
        tokenIDHasProof[_tokenId] = true;

        //Mint using internal function
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _metadataUri);
    }

    function percentageOfCirculatingSupplyOwned(address _queryAddress) public view returns (uint256) {
        return readCurrentRndrBalance(_queryAddress) / circulatingSupplyOfRndr();
    }

    function circulatingSupplyOfGenesisToken() public view returns (uint256) {
        uint256 nonCirculatingSupply = 0;

        for (uint i; i < addressesNotInCirculatingSupply.length; i++) {
            nonCirculatingSupply = nonCirculatingSupply + readCurrentGenesisTokenBalance(addressesNotInCirculatingSupply[i]);
        }

        return IERC20(RNDRTokenAddress).totalSupply() - nonCirculatingSupply;
    }

    function circulatingSupplyOfRndr() public view returns (uint256) {
        uint256 nonCirculatingSupply = 0;

        for (uint i; i < addressesNotInCirculatingSupply.length; i++) {
            nonCirculatingSupply = nonCirculatingSupply + readCurrentRndrBalance(addressesNotInCirculatingSupply[i]);
        }

        return IERC20(RNDRTokenAddress).totalSupply() - nonCirculatingSupply;
    }

    function readCurrentRndrBalance(address _queryAddress) public view returns (uint256) {
        return IERC20(RNDRTokenAddress).balanceOf(_queryAddress);
    }

    function readCurrentGenesisTokenBalance(address _queryAddress) public view returns (uint256) {
        return IERC20(GenesisTokenAddress).balanceOf(_queryAddress);
    }

    function removeFromNonCirculatingSupplyMapping(address _addressToRemove) external onlyMinter {
        for (uint i; i < addressesNotInCirculatingSupply.length; i++) {
            if (addressesNotInCirculatingSupply[i] == _addressToRemove) {
                delete addressesNotInCirculatingSupply[i];
            }
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }
}
