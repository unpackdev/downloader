// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**

   .-.                   .-.              
   : :                   : :              
 _ : : .--.  ,-.,-. .--. : :   .--.  .--. 
: :; :' .; ; : ,. :' .; :: :_ ' '_.'`._-.'
`.__.'`.__,_;:_;:_;`._. ;`.__;`.__.'`.__.'
                    .-. :                 
                    `._.'                 
 */

//** OpenZeppelin Dependencies Upgradeable */
import "./ECDSAUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./MathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
//** OpenZepplin non-upgradeable */
import "./IERC20.sol";
import "./Pausable.sol";

// Dependencies

contract JanglesToken is
    ERC20Upgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    Pausable
{
    // Using
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // Structs
    struct Multipliers {
        uint64 rare;
        uint64 count;
        uint64 maxNft;
        uint64 _gap;
    }

    //** Role Variables */
    bytes32 private constant MINTER_ROLE = keccak256('MINTER_ROLE');

    // Variables for mint for hold
    uint256 public start;
    uint256 public janglesPerSecond;
    address private signer;
    uint256 maxClaimTime;
    // Contracts
    IERC721EnumerableUpgradeable public bojangles;
    // Sets Structs n Mappings
    Multipliers multipliers;
    mapping(uint256 => uint256) public lastClaimOnNft;
    mapping(address => uint256) public slothClaimers;
    EnumerableSetUpgradeable.UintSet internal rares;

    /** Bot Protection */
    mapping(address => uint256) public _timeOfLastTransfer;
    mapping(address => bool) public _blacklist;
    mapping(address => bool) public _whitelist;
    bool public timeLimited;
    mapping(address => bool) public pairs;
    mapping(address => bool) public routers;
    uint256 public timeBetweenTransfers;

    // Black list for bots */
    modifier isBlackedListed(address sender, address recipient) {
        require(
            _blacklist[sender] == false,
            'ERC20: Account is blacklisted from transferring'
        );
        _;
    }

    //** Role Modifiers */
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }

    /** @dev addMinters: Allow lPool to become a minter. Can add more for other pools / farms in future 
        @param instances {address[]}
    */
    function addMinters(address[] calldata instances) external onlyOwner {
        for (uint256 index = 0; index < instances.length; index++) {
            _setupRole(MINTER_ROLE, instances[index]);
        }
    }

    /** @dev mint:Staking portal will have the ability to mint. 
        @param to {address}
        @param amount {uint256}
    */
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    /** @dev mintForUser: Hold NFT to mint tokens. 
        @param user {address}

        note: Anybody can call this function for any user. #goodAccounting? :kek:
    */
    function mintForUser(address user) external {
        uint256 total = bojangles.balanceOf(user);
        uint256 owed = 0;
        for (uint256 i = 0; i < total; i++) {
            uint256 id = bojangles.tokenOfOwnerByIndex(user, i);
            uint256 claimed = lastClaim(id);
            if (rares.contains(id)) {
                owed += ((block.timestamp - claimed) *
                    ((janglesPerSecond * multipliers.rare) / 100));
            } else {
                owed += ((block.timestamp - claimed) * janglesPerSecond);
            }
            lastClaimOnNft[id] = block.timestamp;
        }
        uint256 multiplier =
            90 +
                MathUpgradeable.min(total, multipliers.maxNft) *
                multipliers.count;
        owed = (owed * multiplier) / 100;

        _mint(user, owed);
    }

    /** @dev userOwed: FrontendFunction....
        @param user {address}
    */
    function userOwed(address user) external view returns (uint256) {
        uint256 total = bojangles.balanceOf(user);
        uint256 owed = 0;
        for (uint256 i = 0; i < total; i++) {
            uint256 id = bojangles.tokenOfOwnerByIndex(user, i);
            uint256 claimed = lastClaim(id);
            if (rares.contains(id)) {
                owed += ((block.timestamp - claimed) *
                    ((janglesPerSecond * multipliers.rare) / 100));
            } else {
                owed += ((block.timestamp - claimed) * janglesPerSecond);
            }
        }
        uint256 multiplier =
            90 +
                MathUpgradeable.min(total, multipliers.maxNft) *
                multipliers.count;
        owed = (owed * multiplier) / 100;

        return owed;
    }

    /** @dev claim: Sleepy Sloth Holders will have the ability to 
        @param signature {bytes}
        @param _amount {uint256}
     */
    function claim(bytes memory signature, uint256 _amount) external {
        require(maxClaimTime > block.timestamp, 'CLAIM: Time has passed bud.');
        bytes32 messageHash = sha256(abi.encode(msg.sender, _amount));
        bool recovered =
            ECDSAUpgradeable.recover(messageHash, signature) == signer;

        require(recovered == true, 'CLAIM: Record not found bud.');
        require(
            slothClaimers[msg.sender] == 0,
            "CLAIM: You can't claim twice there bud."
        );
        slothClaimers[msg.sender] = _amount;

        _mint(msg.sender, _amount);
    }

    /** Getters -------------------------------- */
    function lastClaim(uint256 id) public view returns (uint256) {
        return MathUpgradeable.max(lastClaimOnNft[id], start);
    }

    /** Setters -------------------------------- */

    /** @dev set signer: Signer is address that created claims
        @param _signer {address}
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /** @dev set rare multiplier: Multiplier for rare nft set
        @param multiplier {uint64}

        note: starts at 100 for 1:1 with normal
     */
    function setRareMultiplier(uint64 multiplier) external onlyOwner {
        multipliers.rare = multiplier;
    }

    /** @dev set count multiplier: # of bojangles multiplier
        @param multiplier {uint64}

        note: setting to 10 means if user has 11 nfts they get 200% extra.
     */
    function setCountMultiplier(uint64 multiplier) external onlyOwner {
        multipliers.count = multiplier;
    }

    /** @dev set max nft multiplier: # nfts until multiplier cuts off
        @param multiplier {uint64}
     */
    function setMaxNftMultiplier(uint64 multiplier) external onlyOwner {
        multipliers.maxNft = multiplier;
    }

    /** @dev setMultiplier: Look at previous FN's for details on each params.
        @param rare {uint64}
        @param count {uint64}
        @param maxNft {uint64}
     */
    function setMultiplier(
        uint64 rare,
        uint64 count,
        uint64 maxNft
    ) external onlyOwner {
        multipliers = Multipliers({
            rare: rare,
            count: count,
            maxNft: maxNft,
            _gap: 0
        });
    }

    /** Add rares we missed. */
    function addRare(uint256 rareId) external onlyOwner {
        rares.add(rareId);
    }

    /** note get all rate nft ids */
    function getRares() external view returns (uint256[] memory) {
        uint256[] memory _rares = new uint256[](rares.length());

        for (uint256 i = 0; i < rares.length(); i++) {
            _rares[i] = rares.at(i);
        }

        return _rares;
    }

    /** Transfer Blacklist */
    function isTimeLimited(address sender, address recipient) internal {
        if (
            timeLimited &&
            _whitelist[recipient] == false &&
            _whitelist[sender] == false
        ) {
            address toDisable = sender;
            if (pairs[sender] == true) {
                toDisable = recipient;
            } else if (pairs[recipient] == true) {
                toDisable = sender;
            }

            if (
                pairs[toDisable] == true ||
                routers[toDisable] == true ||
                toDisable == address(0)
            ) return; // Do nothing as we don't want to disable router

            if (_timeOfLastTransfer[toDisable] == 0) {
                _timeOfLastTransfer[toDisable] = block.timestamp;
            } else {
                require(
                    block.timestamp - _timeOfLastTransfer[toDisable] >
                        timeBetweenTransfers,
                    'ERC20: Time since last transfer must be greater then time to transfer'
                );
                _timeOfLastTransfer[toDisable] = block.timestamp;
            }
        }
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        isBlackedListed(msg.sender, recipient)
        returns (bool)
    {
        isTimeLimited(msg.sender, recipient);
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        whenNotPaused
        isBlackedListed(sender, recipient)
        returns (bool)
    {
        isTimeLimited(msg.sender, recipient);
        return super.transferFrom(sender, recipient, amount);
    }

    function setTimeLimited(bool _timeLimited) external onlyOwner {
        timeLimited = _timeLimited;
    }

    function setTimeBetweenTransfers(uint256 _timeBetweenTransfers)
        external
        onlyOwner
    {
        timeBetweenTransfers = _timeBetweenTransfers;
    }

    function setPair(address _pair, bool _isPair) external onlyOwner {
        pairs[_pair] = _isPair;
    }

    function setRouter(address _router, bool _isRouter) external onlyOwner {
        routers[_router] = _isRouter;
    }

    function setBlackListedAddress(address account, bool blacklisted)
        external
        onlyOwner()
    {
        _blacklist[account] = blacklisted;
    }

    function setWhiteListedAddress(address _address, bool _whitelisted)
        external
        onlyOwner
    {
        _whitelist[_address] = _whitelisted;
    }

    //to recieve ETH
    receive() external payable {}
}
