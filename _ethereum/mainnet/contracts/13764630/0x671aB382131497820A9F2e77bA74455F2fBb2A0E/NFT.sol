// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./console.sol";
import "./Token.sol";

contract DapperDeer is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    CountersUpgradeable.Counter private _employeeIdCounter;

    uint256 public cost;

    uint128 public maxSupply;
    uint128 public maxMintAmount;
    uint128 public publicMintStartTime;
    uint128 public employeeMaxSupply;
    uint128 public employeeCost;

    string public baseURI;

    Bucks bucks;

    enum Job {
        RETAIL,
        HEDGE_FUND,
        EMPLOYEE
    }

    struct Deer {
        Job job;
        uint88 lastClaim;
        int160 hedgeClaimed;
    }

    mapping(uint256 => Deer) public deers;

    int256 private _bucksPerHedgeFundManager;
    uint256 private _totalHedgeFundManagers;

    uint256 public constant BUCKS_PER_DAY = 500 ether;
    uint256 public constant EMPLOYEE_BUCKS_PER_DAY = 100 ether;

    uint256 public constant LOTTERY_TICKET_PRICE = 50 ether;
    uint256 public constant LOTTERY_TICKET_PAYOUT = 50_000 ether;

    mapping(address => int256) private _amountEarnedPerAddress;
    address[] private _earnedAddresses;

    bool public gamePaused;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint256 _cost,
        uint128 _maxSupply,
        uint128 _maxPerTx,
        uint128 _mintStart,
        uint128 _employeeCost,
        uint128 _employeeMaxSupply,
        address _bucks
    ) public initializer {
        __ERC721_init("Dapper Deers Inc.", "DEER");
        __ERC721Enumerable_init();
        __Ownable_init();

        publicMintStartTime = _mintStart;
        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmount = _maxPerTx;
        employeeMaxSupply = _employeeMaxSupply;
        employeeCost = _employeeCost;
        bucks = Bucks(_bucks);
        gamePaused = false;
    }

    /////////////////////////////////////////////////////////////
    // MINTING
    /////////////////////////////////////////////////////////////
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = _tokenIdCounter.current();
        require(_mintAmount > 0, "amount must be >0");
        require(_mintAmount <= maxMintAmount, "amount must < max");
        require(supply + _mintAmount <= maxSupply, "sold out!");

        if (msg.sender != owner()) {
            require(block.timestamp > publicMintStartTime, "mint locked");
            require(msg.value >= cost * _mintAmount, "no funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
            _initToken(tokenId);
        }
    }

    function safeMint(address to, Job job) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTimes(tokenId, job);
        if (job == Job.HEDGE_FUND) _totalHedgeFundManagers++;
    }

    function _initToken(uint256 _id) private {
        uint256 _rand = random(_id);
        Job job = (_rand % 10 == 0) ? Job.HEDGE_FUND : Job.RETAIL;
        if (job == Job.HEDGE_FUND) _totalHedgeFundManagers++;
        _setTimes(_id, job);
    }

    function _setTimes(uint256 _id, Job job) private {
        if (job == Job.RETAIL || job == Job.EMPLOYEE) {
            deers[_id] = Deer({
                job: job,
                lastClaim: uint80(block.timestamp),
                hedgeClaimed: 0
            });
        } else {
            deers[_id] = Deer({
                job: job,
                lastClaim: uint80(block.timestamp),
                hedgeClaimed: int160(_bucksPerHedgeFundManager)
            });
        }
    }

    /////////////////////////////////////////////////////////////
    // GAMEPLAY
    /////////////////////////////////////////////////////////////
    ////////////////////////
    // CLAIMING
    ////////////////////////
    function claimToken(uint256[] calldata _ids) public {
        require(!gamePaused, "game paused");
        int256 owed = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            owed += _claim(_ids[i]);
        }
        _updateEarned(msg.sender, owed);
        if (owed > 0) bucks.mint(msg.sender, uint256(owed));
    }

    function wageOwed(uint256 _id) public view returns (uint256 owed) {
        Deer storage deer = deers[_id];
        uint256 bucksPerDay = (deer.job == Job.EMPLOYEE)
            ? EMPLOYEE_BUCKS_PER_DAY
            : BUCKS_PER_DAY;
        owed = uint256(
            ((block.timestamp - deer.lastClaim) * bucksPerDay) / 1 days
        );
    }

    function taxOwed(uint256 _id) private view returns (int256 owed) {
        Deer storage deer = deers[_id];
        owed = 0;
        // give tax if hedge fund manager
        if (deer.job == Job.HEDGE_FUND) {
            owed = _bucksPerHedgeFundManager - deer.hedgeClaimed;
        }
    }

    function _claim(uint256 _id) internal returns (int256) {
        require(ownerOf(_id) == msg.sender, "not yours");
        Deer storage deer = deers[_id];
        int256 owed = int256(wageOwed(_id)) + taxOwed(_id);
        deer.lastClaim = uint80(block.timestamp);
        if (deer.job == Job.HEDGE_FUND) {
            deer.hedgeClaimed = int160(_bucksPerHedgeFundManager);
        }
        return owed;
    }

    ////////////////////////
    // GAMBLE
    ////////////////////////
    function entrepreneurship(uint256 _amount) public {
        require(!gamePaused, "game paused");
        require(bucks.balanceOf(msg.sender) >= _amount, "not enough funds");
        uint256 random = random(1);
        bool success = (random % 20) < 9;
        if (success) {
            int256 owed = int256(_amount);
            _bucksPerHedgeFundManager -= owed / int256(_totalHedgeFundManagers);
            bucks.mint(msg.sender, uint256(owed));
            _updateEarned(msg.sender, owed);
        } else {
            // Distribute to hedge fund managers
            _bucksPerHedgeFundManager += int256(
                _amount / _totalHedgeFundManagers
            );

            // Remove funds from the owner
            bucks.burn(msg.sender, _amount);
            _updateEarned(msg.sender, -int256(_amount));
        }
    }

    function degenCallOption(uint256 _amount) public {
        require(!gamePaused, "game paused");
        require(bucks.balanceOf(msg.sender) >= _amount, "not enough funds");
        uint256 random = random(1);
        bool success = (random % 14) == 1;
        if (success) {
            int256 owed = int256(_amount) * 9;
            _bucksPerHedgeFundManager -= owed / int256(_totalHedgeFundManagers);
            bucks.mint(msg.sender, uint256(owed));
            _updateEarned(msg.sender, owed);
        } else {
            // Distribute to hedge fund managers
            _bucksPerHedgeFundManager += int256(
                _amount / _totalHedgeFundManagers
            );

            // Remove funds from the owner
            bucks.burn(msg.sender, _amount);
            _updateEarned(msg.sender, -int256(_amount));
        }
    }

    function lotteryTicket() public {
        require(!gamePaused, "game paused");
        require(
            bucks.balanceOf(msg.sender) >= LOTTERY_TICKET_PRICE,
            "not enough funds"
        );
        uint256 random = random(1);
        bool success = (random % 2000) == 1;
        if (success) {
            _bucksPerHedgeFundManager -= int256(
                LOTTERY_TICKET_PAYOUT / _totalHedgeFundManagers
            );
            bucks.mint(msg.sender, LOTTERY_TICKET_PAYOUT);
            _updateEarned(msg.sender, int256(LOTTERY_TICKET_PAYOUT));
        } else {
            // Distribute to hedge fund managers
            _bucksPerHedgeFundManager += int256(
                LOTTERY_TICKET_PRICE / _totalHedgeFundManagers
            );

            // Remove funds from the owner
            bucks.burn(msg.sender, LOTTERY_TICKET_PRICE);
            _updateEarned(msg.sender, -int256(LOTTERY_TICKET_PRICE));
        }
    }

    function _updateEarned(address _address, int256 _amount) internal {
        if (_amountEarnedPerAddress[_address] == 0) {
            _earnedAddresses.push(_address);
        }
        _amountEarnedPerAddress[_address] += _amount;
    }

    /////////////////////////////////////////////////////////////
    // EMPLOYING
    /////////////////////////////////////////////////////////////
    function mintEmployees(uint256 _mintAmount) public {
        uint256 supply = _employeeIdCounter.current();
        require(block.timestamp > publicMintStartTime, "mint locked");
        require(_mintAmount > 0, "amount must be >0");
        require(_mintAmount <= maxMintAmount, "amount must < max");
        require(supply + _mintAmount <= employeeMaxSupply, "sold out!");

        if (msg.sender != owner()) {
            bucks.burn(msg.sender, _mintAmount * employeeCost);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _employeeIdCounter.increment();
            uint256 tokenId = _employeeIdCounter.current() + maxSupply;
            _safeMint(msg.sender, tokenId);
            _setTimes(tokenId, Job.EMPLOYEE);
        }
    }

    /////////////////////////////////////////////////////////////
    // ADMIN READ FUNCTIONS
    /////////////////////////////////////////////////////////////
    function bucksPerHedgeFundManager()
        external
        view
        onlyOwner
        returns (int256)
    {
        return _bucksPerHedgeFundManager;
    }

    function totalHedgeFundManagers()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return _totalHedgeFundManagers;
    }

    function amountEarnedPerAddress(address _address)
        external
        view
        onlyOwner
        returns (int256)
    {
        return _amountEarnedPerAddress[_address];
    }

    function earnedAddresses()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return _earnedAddresses;
    }

    /////////////////////////////////////////////////////////////
    // ADMIN
    /////////////////////////////////////////////////////////////
    function withdraw() public payable onlyOwner {
        require(
            payable(owner()).send(address(this).balance),
            "could not withdraw"
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPublicMintStartTime(uint88 _time) public onlyOwner {
        publicMintStartTime = _time;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setPaused(bool _paused) public onlyOwner {
        gamePaused = _paused;
    }

    function random(uint256 _seed) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number == 0 ? 0 : block.number - 1),
                        block.timestamp,
                        _seed
                    )
                )
            );
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
