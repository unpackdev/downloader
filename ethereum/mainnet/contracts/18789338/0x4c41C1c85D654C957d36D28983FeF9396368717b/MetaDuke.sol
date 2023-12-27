// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./EnumerableSet.sol";

import "./MetaDukeEvents.sol";
import "./MetaDukeStructsErrors.sol";
import "./ERC721SeaDrop.sol";


contract MetaDuke is ERC721SeaDrop, MetaDukeStructsErrors, MetaDukeEvents {
    using EnumerableSet for EnumerableSet.UintSet;
    address private _admin;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant L1_SUPPLY = 121;
    uint256 public constant L2_SUPPLY = 220;
    uint256 public constant L3_SUPPLY = 9659;

    uint256 public constant WHITELIST_ROUND_ID = 1;
    uint256 public constant PUBLIC_ROUND_ID = 2;
    // roundId => mapping(address => mintCount)
    mapping(uint256 => mapping(address => uint256)) internal _acccountMintCount;

    mapping(uint256 => Round) internal _round;

    mapping(uint256 => mapping(address => bool)) internal _whitelist;
    mapping(uint256 => uint256) public whitelistCounter;

    mapping(uint256 => EnumerableSet.UintSet) internal _roundTokenIds;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721SeaDrop(name, symbol, allowedSeaDrop) {}

    receive() external payable virtual {}

    modifier onlyAdmin {
        _checkAdmin();
        _;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function _checkAdmin() internal view virtual {
        require(owner() == msg.sender || admin() == msg.sender, "MetaDukes: caller is not admin");
    }

    function renounceAdmin() public virtual onlyOwner {
        _transferAdmin(address(0));
    }

    function transferAdmin(address newAdmin) public virtual onlyOwner {
        require(newAdmin != address(0), "MetaDukes: new owner is the zero address");
        _transferAdmin(newAdmin);
    }

    function _transferAdmin(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    function _checkRoundId(uint256 _roundId) internal view virtual {
        if (_roundId != WHITELIST_ROUND_ID && _roundId != PUBLIC_ROUND_ID) {
            revert InvalidRound();
        }
    }

    function _getAccountMintCount(uint256 _roundId, address _account) internal view virtual returns (uint256) {
        return _acccountMintCount[_roundId][_account];
    }

    function _isWhitelist(uint256 _roundId, address _account) internal view returns (bool) {
        return _whitelist[_roundId][_account];
    }

    //==========================================
    //------------- Round --------------
    //==========================================
    function setRound(
        uint256 _roundId,
        bool _isActive,
        uint256 _start,
        uint256 _end,
        uint256 _price,
        uint256 _limit,
        uint256 _supply,
        uint256 _cap
    ) external virtual onlyAdmin {
        _checkRoundId(_roundId);

        if (_end <= block.timestamp) {
            revert InvalidEnd();
        }
        if (_start >= _end) {
            revert InvalidStart();
        }
        if (_roundId == WHITELIST_ROUND_ID) {
            if (_supply > L2_SUPPLY) {
                revert InvalidSupply();
            }
            if (_cap > L2_SUPPLY) {
                revert InvalidCap();
            }
        } else {
            if (_supply > L3_SUPPLY) {
                revert InvalidSupply();
            }
            if (_cap > L3_SUPPLY) {
                revert InvalidCap();
            }
        }

        Round storage round = _round[_roundId];
        round.id = _roundId;
        round.isActive = _isActive;
        round.start = _start;
        round.end = _end;
        round.price = _price;
        round.limit = _limit;
        round.supply = _supply;
        round.cap = _cap;

        emit SetRound(
            msg.sender,
            _roundId,
            _isActive,
            _start,
            _end,
            _limit,
            _supply,
            _cap,
            _price
        );
    }

    function activateRound(uint256 _roundId) external virtual onlyAdmin {
        _checkRoundId(_roundId);

        _round[_roundId].isActive = true;
        emit SetRoundStatus(msg.sender, _roundId, true);
    }

    function deactivateRound(uint256 _roundId) external virtual onlyAdmin {
        _checkRoundId(_roundId);

        _round[_roundId].isActive = false;
        emit SetRoundStatus(msg.sender, _roundId, false);
    }

    function getRound(uint256 _roundId) external view virtual returns (Round memory) {
        return _round[_roundId];
    }

    function getCurrentRound() external view virtual returns (Round memory) {
        Round memory round;
        for (uint256 id = 1; id <= PUBLIC_ROUND_ID; id++) {
            round = _round[id];
            if (round.end >= block.timestamp) {
                return round;
            } else {
                continue;
            }
        }
        return round;
    }

    function getRoundTokenIds(uint256 _roundId) public view virtual returns (uint256[] memory) {
        return _roundTokenIds[_roundId].values();
    }

    function getRoundTokenCount(uint256 _roundId) public view virtual returns (uint256) {
        return _roundTokenIds[_roundId].length();
    }

    //==========================================
    //------------- Public Mint --------------
    //==========================================
    function getAccountMintCount(uint256 _roundId, address _account) external view virtual returns (uint256) {
        _checkRoundId(_roundId);
        return _getAccountMintCount(_roundId, _account);
    }

    function mint(uint256 _roundId, uint256 _amount) external payable virtual {
        _checkRoundId(_roundId);
        if (_amount <= 0) revert MintZeroAmount();

        Round storage round = _round[_roundId];
        if (!round.isActive) {
            revert InactiveRound();
        }
        if (round.start > block.timestamp) {
            revert NotStartRound();
        }
        if (round.end < block.timestamp) {
            revert EndedRound();
        }
        if ((totalSupply() + _amount) > MAX_SUPPLY) {
            revert ExceedMaxSupply();
        }

        address minter = msg.sender;
        uint256 payment;
        uint256 startTokenId = totalSupply();
        uint256 whitelistAmount;
        Round storage whitelistRound = _round[WHITELIST_ROUND_ID];

        if (_roundId == WHITELIST_ROUND_ID) {
            if (!_isWhitelist(_roundId, minter)) revert NotWhitelist();
        } else if (_isWhitelist(WHITELIST_ROUND_ID, minter)) {
            uint256 whitelistMintCount = _getAccountMintCount(WHITELIST_ROUND_ID, minter);
            uint256 accountWhitelistRemaining = whitelistRound.limit - whitelistMintCount;
            if (accountWhitelistRemaining > 0) {
                if (_amount < accountWhitelistRemaining) {
                    whitelistAmount = _amount;
                    _amount = 0;
                } else {
                    whitelistAmount = accountWhitelistRemaining;
                    _amount -= whitelistAmount;
                }
                payment = whitelistRound.price * whitelistAmount;
            }
        }

        if (_amount > round.cap) {
            revert ExceedRoundSupply();
        }

        payment += round.price * _amount;

        if (_getAccountMintCount(_roundId, minter) + _amount > round.limit) revert ExceedRoundLimit();
        if (msg.value < payment) revert InsufficientBalance();

        if (whitelistAmount > 0) {
            _safeMint(minter, whitelistAmount);
            for (uint256 i = 1; i <= whitelistAmount; i++) {
                _roundTokenIds[WHITELIST_ROUND_ID].add(startTokenId+i);
                emit Minted(minter, WHITELIST_ROUND_ID, startTokenId+i);
            }

            startTokenId += whitelistAmount;
            whitelistRound.cap -= whitelistAmount;
            _acccountMintCount[WHITELIST_ROUND_ID][minter] += whitelistAmount;
        }

        if (_amount > 0) {
            _safeMint(minter, _amount);
            for (uint256 i = 1; i <= _amount; i++) {
                _roundTokenIds[_roundId].add(startTokenId+i);
                emit Minted(minter, _roundId, startTokenId+i);
            }

            round.cap -= _amount;
            _acccountMintCount[_roundId][minter] += _amount;
        }

        if (msg.value - payment > 0) {
            (bool success, ) = payable(minter).call{value: msg.value - payment}("");
            if (!success) revert FailRefund();
        }
    }

    function isWhitelist(uint256 _roundId, address _account) external view returns (bool) {
        _checkRoundId(_roundId);
        if (_roundId == WHITELIST_ROUND_ID) {
            return _isWhitelist(_roundId, _account);
        } else {
            return true;
        }
    }

    //==========================================
    //------------- Private Mint --------------
    //==========================================
    function privateMint(address _account, uint256 _roundId, uint256 _amount) public virtual onlyAdmin {
        _checkRoundId(_roundId);
        if (_amount <= 0) revert MintZeroAmount();

        uint256 startTokenId = totalSupply();
        if ((startTokenId + _amount) > MAX_SUPPLY) revert ExceedMaxSupply();

        Round storage round = _round[_roundId];
        if (_amount > round.cap) {
            revert ExceedRoundSupply();
        }

        _safeMint(_account, _amount);
        for (uint256 i = 1; i <= _amount; i++) {
            _roundTokenIds[_roundId].add(startTokenId+i);
            emit PrivateMinted(msg.sender, _account, _roundId, startTokenId+i);
        }

        round.cap -= _amount;
    }

    function marketMint(address _account, uint256 _amount) public virtual onlyAdmin {
        if (_amount <= 0) revert MintZeroAmount();

        uint256 startTokenId = totalSupply();
        if ((startTokenId + _amount) > MAX_SUPPLY) revert ExceedMaxSupply();
        if ((_roundTokenIds[0].length() + _amount) > L1_SUPPLY) revert ExceedMarketMintSupply();

        _safeMint(_account, _amount);
        for (uint256 i = 1; i <= _amount; i++) {
            _roundTokenIds[0].add(startTokenId+i);
            emit MarketMinted(msg.sender, _account, startTokenId+i);
        }
    }

    //==========================================
    //------------- Admin --------------
    //==========================================
    function addWhitelist(uint256 _roundId, address[] memory _addrs) public onlyAdmin {
        if (_roundId == WHITELIST_ROUND_ID) {
            if (whitelistCounter[_roundId] + _addrs.length > L2_SUPPLY) revert ExceedWhitelistLimit();
        }

        for (uint256 i = 0; i < _addrs.length; i++) {
            if (!_isWhitelist(_roundId, _addrs[i])) {
                _whitelist[_roundId][_addrs[i]] = true;
                whitelistCounter[_roundId]++;
            }
        }
    }

    function removeWhitelist(uint256 _roundId, address[] memory _addrs) public onlyAdmin {
        for (uint256 i = 0; i < _addrs.length; i++) {
            if (_isWhitelist(_roundId, _addrs[i])) {
                _whitelist[_roundId][_addrs[i]] = false;
                whitelistCounter[_roundId]--;
            }
        }
    }

    function withdraw() public virtual onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) revert FailWithdraw();
    }

    function _startTokenId() internal view virtual override(ERC721SeaDrop) returns (uint256) {
        return 1;
    }
}
