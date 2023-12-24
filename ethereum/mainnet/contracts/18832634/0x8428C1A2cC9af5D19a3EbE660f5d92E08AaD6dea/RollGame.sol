// SPDX-License-Identifier: MIT

// Official Game Token Address: 0x588cc699526e93aa0352Bc515Ff53522c8211e67

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity ^0.8.0;

contract RollToken is Ownable, ERC20 {
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor(uint256 _totalSupply) ERC20("ROLL", "ROLL") {
        _mint(msg.sender, _totalSupply);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {}

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}

pragma solidity ^0.8.0;

contract RollGame is Ownable {

    address public rewardWallet;
    address public admin;

    RollToken public immutable bettingToken;

    uint256 public minimumBet;
    uint256 public rewardRate;
    uint256 public burnRate;
    int64[] public activeTgGroups;
    mapping(int64 => Game) public games;
    mapping(address => uint256) public winningsBalances;
    mapping(address => uint256) public burnBalances;
    mapping(address => uint256) public rewardBalances; 

    event Bet(int64 tgChatId, address player, uint16 playerIndex, uint256 amount);
    event Win(int64 tgChatId, address player, uint16 playerIndex, uint256 amount);
    event Loss(int64 tgChatId, address player, uint16 playerIndex, uint256 amount);
    event Reward(uint256 amount);
    event Burn(uint256 amount);

    constructor(address payable _bettingToken, uint256 _rewardRate, uint256 _burnRate, address _rewardWallet) {
        rewardWallet = _rewardWallet;
        rewardRate = _rewardRate;
        burnRate = _burnRate;
        bettingToken = RollToken(_bettingToken);
    }

    struct Game {
        address[] players;
        uint256[] bets;

        bool inProgress;
        uint16[] losers;
    }

    function isGameInProgress(int64 _tgChatId) public view returns (bool) {
        return games[_tgChatId].inProgress;
    }

    function isLoser(uint16 playerIndex, uint16[] memory losers) internal pure returns (bool) {
        for (uint256 i = 0; i < losers.length; i++) {
            if (losers[i] == playerIndex) {
                return true;
            }
        }
        return false;
    }

    function removeTgId(int64 _tgChatId) internal {
        for (uint256 i = 0; i < activeTgGroups.length; i++) {
            if (activeTgGroups[i] == _tgChatId) {
                activeTgGroups[i] = activeTgGroups[activeTgGroups.length - 1];
                activeTgGroups.pop();
            }
        }
    }

    function setMinimumBet(uint256 _minimumBet) public onlyOwner {
        minimumBet = _minimumBet;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function newGame(int64 _tgChatId, address[] memory _players, uint256[] memory _bets) public returns (uint256[] memory) {
        require(msg.sender == admin);
        require(_players.length == _bets.length, "Players/bets length mismatch");
        require(_players.length > 1, "Not enough players");
        require(!isGameInProgress(_tgChatId), "There is already a game in progress");

        uint256 betTotal = 0;
        for (uint16 i = 0; i < _bets.length; i++) {
            require(_bets[i] >= minimumBet, "Bet is smaller than the minimum");
            betTotal += _bets[i];
        }
        for (uint16 i = 0; i < _bets.length; i++) {
            betTotal -= _bets[i];
            if (_bets[i] > betTotal) {
                _bets[i] = betTotal;
            }
            betTotal += _bets[i];

            require(bettingToken.allowance(_players[i], address(this)) >= _bets[i], "Not enough allowance");
            bool isSent = bettingToken.transferFrom(_players[i], address(this), _bets[i]);
            require(isSent, "Funds transfer failed");

            emit Bet(_tgChatId, _players[i], i, _bets[i]);
        }

        Game memory g;
        g.players = _players;
        g.bets = _bets;
        g.inProgress = true;

        games[_tgChatId] = g;
        activeTgGroups.push(_tgChatId);

        return _bets;
    }

    function endGame(int64 _tgChatId, uint16[] memory _losers) public {
        require(msg.sender == admin);
        require(isGameInProgress(_tgChatId), "No game in progress for this Telegram chat ID");

        Game storage g = games[_tgChatId];

        require(g.players.length > 1, "Not enough players");

        g.losers = _losers;
        g.inProgress = false;
        removeTgId(_tgChatId);

        address[] memory winners = new address[](g.players.length - _losers.length);
        uint16[] memory winnersPlayerIndex = new uint16[](g.players.length - _losers.length);

        uint256 winningBetTotal = 0;

        {
            uint16 numWinners = 0;
            for (uint16 i = 0; i < g.players.length; i++) {
                if (!isLoser(i, _losers)) {
                    winners[numWinners] = g.players[i];
                    winnersPlayerIndex[numWinners] = i;
                    winningBetTotal += g.bets[i];
                    numWinners++;
                }
            }
        }

        uint256 totalPaidWinnings = 0;
        require(burnRate + rewardRate < 100, "Total fees must be < 100%");

        uint256 burnShare = 0;
        for (uint256 i = 0; i < _losers.length; i++) {
            uint256 loserIndex = _losers[i];
            burnShare += g.bets[loserIndex] * burnRate / 100;
        }

        uint256 approxRewardShare = 0;
        for (uint256 i = 0; i < _losers.length; i++) {
            uint256 loserIndex = _losers[i];
            approxRewardShare += g.bets[loserIndex] * rewardRate / 100;
        }
        
        uint256 losersBets = 0;
        for (uint256 i = 0; i < _losers.length; i++) {
            uint256 loserIndex = _losers[i];
            losersBets += g.bets[loserIndex];
        }
        uint256 totalWinnings = losersBets - burnShare - approxRewardShare;

        for (uint16 i = 0; i < winners.length; i++) {
            uint256 winnings = totalWinnings * g.bets[winnersPlayerIndex[i]] / winningBetTotal;

            winningsBalances[winners[i]] += g.bets[winnersPlayerIndex[i]] + winnings;

            emit Win(_tgChatId, winners[i], winnersPlayerIndex[i], winnings);

            totalPaidWinnings += winnings;
        }

        burnBalances[owner()] += burnShare;

        uint256 realRewardShare = losersBets - totalPaidWinnings - burnShare;
        rewardBalances[owner()] += realRewardShare;

        require((totalPaidWinnings + burnShare + realRewardShare) == losersBets, "Calculated winnings do not add up");
    }

    function abortGame(int64 _tgChatId) public {
        require(msg.sender == admin);
        require(isGameInProgress(_tgChatId), "No game in progress for this Telegram chat ID");
        Game storage g = games[_tgChatId];

        for (uint16 i = 0; i < g.players.length; i++) {
            bool isSent = bettingToken.transfer(g.players[i], g.bets[i]);
            require(isSent, "Funds transfer failed");
        }

        g.inProgress = false;
        removeTgId(_tgChatId);
    }

    function abortAllGames() public {
        require(msg.sender == admin);
        int64[] memory _activeTgGroups = activeTgGroups;
        for (uint256 i = 0; i < _activeTgGroups.length; i++) {
            abortGame(_activeTgGroups[i]);
        }
    }

    function setRates(uint256 _rewardRate, uint256 _burnRate) public onlyOwner {
        require((_rewardRate + _burnRate) <= 10, "Taxes are too high");
        rewardRate = _rewardRate;
        burnRate = _burnRate;
    }

    function claimWinnings() public {
        require(winningsBalances[msg.sender] > 0, "You have no winnings");
        bool isSent;
        uint256 playerWinnings = winningsBalances[msg.sender]; 
        winningsBalances[msg.sender] = 0;
        isSent = bettingToken.transfer(msg.sender, playerWinnings);
        require(isSent, "Funds transfer failed");
    }

    function burnAndReward() public onlyOwner {
        uint256 burnedTokens = burnBalances[owner()];
        uint256 rewardTokens = rewardBalances[owner()]; 
        burnBalances[owner()] = 0;
        rewardBalances[owner()] = 0;
        bettingToken.burn(burnedTokens);
        bettingToken.transfer(rewardWallet, rewardTokens);

        emit Burn(burnedTokens);
        emit Reward(rewardTokens);
    }    
}