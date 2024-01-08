//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./Ownable.sol";

import "./ICryptoBees.sol";
import "./IHoney.sol";
import "./IHive.sol";
import "./Traits.sol";
import "./Randomizer.sol";
import "./IAttack.sol";

contract CryptoBees is ICryptoBees, ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    address private constant BEEKEEPER_1 = 0x8F0025FF54879B322582CCBebB1f391b1d5a1FBf;
    address private constant BEEKEEPER_2 = 0xd3feEb12Feb6f371dF5e5587029212A6e2EFC109;
    address private constant BEEKEEPER_3 = 0x0219b3c14d7A374A89Cf8aB3C09036C030B91220;
    address private constant BEEKEEPER_4 = 0xeaF280E23995a65FEa71C726c213e6E8C4612817;
    address private constant BEAR = 0xE9FA9e12293B4BdBa893922bB35B784eE0ff3a9D;

    IERC20 private woolContract = IERC20(0x5B903d60E07Eea4dcd8E6A83aEC23722B0A89ab8);
    IHoney private honeyContract;
    IHive private hiveContract;
    Randomizer private randomizerContract;
    Traits private traitsContract;
    IAttack private attackContract;

    // there will only ever be (roughly) 0.5 billion $HONEY earned through staking
    uint256 public constant MAXIMUM_GLOBAL_HONEY = 500000000;

    // amount of $HONEY earned so far
    uint256 public totalHoneyEarned;
    // where we at with revealing
    uint256 public unrevealedTokenIndex;
    // number of tokens have been minted so far
    uint256 public minted;
    uint256 public bearsMinted;
    uint256 public beekeepersMinted;
    // mapping from tokenId to a struct containing the token's traits + data
    mapping(uint256 => Token) public tokenData;
    // mapping of $HONEY pots
    mapping(address => uint256) public pot;

    //events
    event Mint(address indexed owner, uint256 tokenId, uint256 blockNumber);
    event HoneyTransfer(address indexed owner, uint256 owed);
    event MintRevealed(address indexed owner, uint256 indexed tokenId, uint256 _type, bool staked);

    constructor() ERC721("CryptoBees Game", "CRYPTOBEES") {}

    function setContracts(
        address honey,
        address hive,
        address traits,
        address attack,
        address rand
    ) external onlyOwner {
        honeyContract = IHoney(honey);
        traitsContract = Traits(traits);
        hiveContract = IHive(hive);
        attackContract = IAttack(attack);
        randomizerContract = Randomizer(rand);
    }

    /**
     * mint a token - 90% Bee, 9% Bear, 1% Beekeeper
     */
    function mintForEth(uint256 amount, bool stake) external payable whenNotPaused nonReentrant {
        traitsContract.mintForEth(_msgSender(), amount, minted, msg.value, stake);
    }

    function mintForEthWhitelist(
        uint256 amount,
        bytes32[] calldata _merkleProof,
        bool stake
    ) external payable whenNotPaused nonReentrant {
        traitsContract.mintForEthWhitelist(_msgSender(), amount, minted, msg.value, _merkleProof, stake);
    }

    function mintForHoney(uint256 amount, bool stake) external whenNotPaused nonReentrant {
        traitsContract.mintForHoney(_msgSender(), amount, minted, stake);
    }

    function mintForWool(uint256 amount, bool stake) external whenNotPaused nonReentrant {
        uint256 totalCost = traitsContract.mintForWool(_msgSender(), amount, minted, stake);
        woolContract.transferFrom(msg.sender, address(this), totalCost);
    }

    function mint(
        address _owner,
        uint256 tokenId,
        bool stake
    ) external {
        require(_msgSender() == address(traitsContract), "BEES:DONT CHEAT:MINT");

        randomizerContract.createCommit();

        minted = tokenId;
        if (!stake) {
            _safeMint(_owner, minted);
        } else {
            _safeMint(address(hiveContract), minted);
            hiveContract.addToWaitingRoom(_owner, tokenId);
        }
        emit Mint(_owner, tokenId, block.number);
        tryReveal();
    }

    /**
     * Revealing of next token in line
     * if the token is staked & is bee move it to the next available hive
     */
    function tryReveal() public returns (bool) {
        if (unrevealedTokenIndex >= minted) return false;
        if (tokenData[unrevealedTokenIndex + 1]._type != 0) return true;

        uint256 seed = randomizerContract.revealSeed(unrevealedTokenIndex);
        if (seed == 0) return false;
        address trueOwner = ownerOf(unrevealedTokenIndex + 1) == address(hiveContract)
            ? hiveContract.getWaitingRoomOwner(unrevealedTokenIndex + 1)
            : ownerOf(unrevealedTokenIndex + 1);
        Token memory t = traitsContract.generate(seed);
        tokenData[unrevealedTokenIndex + 1] = t;
        if (t._type == 2) bearsMinted++;
        if (t._type == 3) beekeepersMinted++;
        if (t._type == 1 && ownerOf(unrevealedTokenIndex + 1) == address(hiveContract)) {
            hiveContract.removeFromWaitingRoom(unrevealedTokenIndex + 1, 0);
        }

        emit MintRevealed(trueOwner, unrevealedTokenIndex + 1, t._type, ownerOf(unrevealedTokenIndex + 1) == address(hiveContract) ? true : false);
        unrevealedTokenIndex += 1;
        return true;
    }

    /**
     * reveal tokens in bulk
     */
    function bulkReveal(uint256 n) public {
        for (uint256 i = 0; i < n; i++) {
            tryReveal();
        }
    }

    function getMinted() external view returns (uint256 m) {
        m = minted;
    }

    /**
     * enables owner to pause / unpause minting
     */

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setUnrevealedTokenIndex(uint256 _index) external onlyOwner {
        unrevealedTokenIndex = _index;
    }

    /**
     * adds honey to a address pot when clamin bee honey or when stealing/collecting
     */
    function increaseTokensPot(address _owner, uint256 amount) external {
        require(_msgSender() == address(attackContract) || _msgSender() == address(hiveContract), "BEES:DONT CHEAT:POT");
        require(totalHoneyEarned + amount < MAXIMUM_GLOBAL_HONEY, "NO MORE HONEY");
        totalHoneyEarned += amount;
        pot[_owner] += amount;
    }

    /**
     * updates bear/beekeeper timestamps
     */
    function updateTokensLastAttack(
        uint256 tokenId,
        uint48 timestamp,
        uint48 till
    ) external {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        require(_msgSender() == address(attackContract), "BEES:DONT CHEAT:ATTACK");
        tokenData[tokenId].lastAttackTimestamp = timestamp;
        tokenData[tokenId].cooldownTillTimestamp = till;
    }

    /**
     * returns sender pot
     */
    function getPotValue() public view returns (uint256) {
        return pot[_msgSender()];
    }

    /**
     * transfers pot to sendrs address - honey in the pot is not stored in 18 decimals
     */
    function transferPotToAddress() public {
        if (pot[_msgSender()] > 0) {
            uint256 amount = pot[_msgSender()] * 1 ether;
            pot[_msgSender()] = 0;
            honeyContract.mint(_msgSender(), amount);
            emit HoneyTransfer(_msgSender(), amount);
        }
    }

    /**
     * returns all your unstaked tokens
     */
    function getTokenIds(address _owner) public view returns (uint256[] memory _tokensOfOwner) {
        _tokensOfOwner = new uint256[](balanceOf(_owner));
        for (uint256 i; i < balanceOf(_owner); i++) {
            _tokensOfOwner[i] = tokenOfOwnerByIndex(_owner, i);
        }
    }

    function getOwnerOf(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        return ownerOf(tokenId);
    }

    function doesExist(uint256 tokenId) external view returns (bool exists) {
        exists = _exists(tokenId);
    }

    function getTokenData(uint256 tokenId) external view returns (Token memory token) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        token = tokenData[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        return traitsContract.tokenURI(tokenId);
    }

    /**
     * withdraw eth
     */
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(BEAR, ((balance * 5) / 100));
        balance = address(this).balance;
        _widthdraw(BEEKEEPER_1, ((balance * 25) / 100));
        _widthdraw(BEEKEEPER_2, ((balance * 25) / 100));
        _widthdraw(BEEKEEPER_3, ((balance * 25) / 100));
        _widthdraw(BEEKEEPER_4, ((balance * 25) / 100));
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to widthdraw Ether");
    }

    /// @notice withdraw ERC20 tokens from the contract
    /// @param erc20TokenAddress the ERC20 token address
    /// @param recipient who will get the tokens
    /// @param amount how many tokens
    function withdrawERC20(
        address erc20TokenAddress,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        IERC20 erc20Contract = IERC20(erc20TokenAddress);
        bool sent = erc20Contract.transfer(recipient, amount);
        require(sent, "ERC20_WITHDRAW_FAILED");
    }

    function performTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        // Hardcode the Hive's approval so that users don't have to waste gas approving
        if (_msgSender() != address(hiveContract)) require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function performSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        // Hardcode the Hive's approval so that users don't have to waste gas approving
        if (_msgSender() != address(hiveContract)) require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, "");
    }
}
