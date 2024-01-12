//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./IStaking.sol";
import "./ITheNFTIslands.sol";
import "./IIslandToken.sol";

contract Staking is IStaking, Ownable, Pausable, IERC721Receiver {

    // external contracts
    ITheNFTIslands public nftIslands; // ERC721
    IIslandToken public islandToken; // ERC20

    struct Stake {
        uint256 tokenId;
        uint256 value;
        address owner;
    }

    // staking data
    mapping(uint256 => Stake) public staking;

    uint256 public numIslandsStaked;

    mapping(uint256 => uint256) public dailyRewardsPerType;

    // project tax on staking claims
    uint256 public projectTax = 20;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event IslandClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 value, uint256 earned);
    event IslandEmergencyUnstaked(uint256 indexed tokenId);

    constructor(ITheNFTIslands _nftIslands) {
        nftIslands = ITheNFTIslands(_nftIslands);
        dailyRewardsPerType[0] = 100 ether;
        dailyRewardsPerType[1] = 150 ether;
        dailyRewardsPerType[2] = 200 ether;
    }

    /*
     * setup contracts
     */
    function setTokenContract(IIslandToken _islandToken)
        external
        onlyOwner
    {
        islandToken = IIslandToken(_islandToken);
    }

    /*
     * only allow function execution if contracts have been set
     *
     * Error messages:
     *  - S0: "CONTRACTS NOT SET"
     */
    modifier requireContractsSet() {
        require(
            address(nftIslands) != address(0) &&
                address(islandToken) != address(0),
            "S0"
        );
        _;
    }

    /*
     * directly stake after minting
     *
     * @param tokenId: id of the staked token
     *
     * Error messages:
     *  - S1: "only NFT smart contract can execute"This token belongs to someone else
     *  - S5: "This token belongs to someone else"
     */
    function stakeFromNFTContract(uint256 tokenId) external {
      require(_msgSender() == address(nftIslands), "S1");
      require(nftIslands.ownerOf(tokenId) == address(this), "S5");

      _addStakedIsland(tx.origin, tokenId);
      numIslandsStaked += 1;
    }

    /*
     * stake multiple tokens into the contract
     *
     * @param tokenIds: ids of the tokens to be staked
     *
     * Error messages:
     *  - S2: "You don't own this token"
     */
    function stakeMultipleTokens(uint256[] calldata tokenIds)
        external
        whenNotPaused
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                nftIslands.ownerOf(tokenIds[i]) == _msgSender(),
                "S2"
            );
            nftIslands.transferFrom(_msgSender(), address(this), tokenIds[i]);

            _addStakedIsland(_msgSender(), tokenIds[i]);
        }
        numIslandsStaked += tokenIds.length;
    }

    /*
     * Add data of token to staking
     *
     * @param _owner: original owner of the token
     * @param _tokenId: id of the token
     */
    function _addStakedIsland(address _owner, uint256 _tokenId) internal {
        staking[_tokenId] = Stake({
            owner: _owner,
            tokenId: _tokenId,
            value: block.timestamp
        });
        emit TokenStaked(_owner, _tokenId, block.timestamp);
    }

    /*
     * Claim $ISLAND ERC20 tokens from multiple staked islands
     *
     * @param tokenIds: list of staked token's id
     * @param unstake: should the tokens be unstaked
     *
     * Error messages:
     *  - S3: "You don't own one of the provided tokens"
     */
    function claimMany(uint256[] calldata tokenIds, bool unstake) external whenNotPaused {
        uint256 owed = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            Stake memory stake = staking[tokenIds[i]];
            require(stake.owner == _msgSender(), "S3");

            uint256 tokenType = nftIslands.getTokenType(tokenIds[i]);
            uint256 dailyReward = dailyRewardsPerType[tokenType];
            owed += ((block.timestamp - stake.value) * dailyReward) / 1 days;

            if (unstake) {
                delete staking[tokenIds[i]];
                numIslandsStaked -= 1;
                nftIslands.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenIds[i]
                );
            } else {
                staking[tokenIds[i]].value = block.timestamp;
            }

            emit IslandClaimed(tokenIds[i], unstake, block.timestamp, owed);
        }
        if (owed == 0) return;
        uint256 withdrawTax = owed * projectTax / 100;
        islandToken.mint(_msgSender(), owed - withdrawTax);
        islandToken.mint(address(islandToken), withdrawTax);
    }

    /*
     * unstake without getting $ISLAND tokens
     *
     * @param tokenIds: list of tokenIds
     *
     * Error messages:
     *  - S3: "You don't own one of the provided tokens"
     */
    function emergencyUnstake(uint256[] calldata tokenIds) external {
      for (uint256 i = 0; i < tokenIds.length; i++) {
            Stake memory stake = staking[tokenIds[i]];
            require(stake.owner == _msgSender(), "S3");

            delete staking[tokenIds[i]];
            numIslandsStaked -= 1;
            nftIslands.safeTransferFrom(
                address(this),
                _msgSender(),
                tokenIds[i]
            );

            emit IslandEmergencyUnstaked(tokenIds[i]);
        }
    }

    /*
     * change tax amount on claim
     *
     * @param _newTax: new tax amount
     *
     * Error messages:
     *  - S4: "tax is too high"
     */
    function setProjectTax(uint256 _newTax) public onlyOwner {
      require(_newTax <= 30, "S4");
      projectTax = _newTax;
    }

    /*
     * pause all staking and claiming - can still unstake with emergency unstake
     */
    function pause() public onlyOwner {
        _pause();
    }

    /*
     * unpause all staking and claiming
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /*
     * check that no ERC721 token is sent directly to the contract
     */
    function onERC721Received(
      address,
      address from,
      uint256,
      bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Staking directly");
      return IERC721Receiver.onERC721Received.selector;
    }
}
