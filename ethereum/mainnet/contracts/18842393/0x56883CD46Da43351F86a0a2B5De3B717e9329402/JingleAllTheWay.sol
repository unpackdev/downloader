//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// https://t.me/JATWerc20
// https://x.com/JAWTerc20
// https://jatw.org/

import "./ERC20.sol";
import "./Ownable2Step.sol";
import "./ITurboNFT.sol";
import "./TurboNFT.sol";
import "./Turbo.sol";

contract JingleAllTheWay is ERC20, Ownable2Step {
    uint256 constant public MAX_SUPPLY = 20231225 ether;
    uint256 constant THRESHOLD = 25122 ether;
    uint256 constant COOLDOWN_OFFSET = 86400;
    uint256 constant BUY_LIMIT = MAX_SUPPLY / 200;
    uint256 constant SELL_LIMIT = MAX_SUPPLY / 500;
    uint256 constant TURBO_LIMIT = 220000000 ether;

    string constant name0 = "JingleAllTheWay";
    string constant symbol0 = "JATW";

    string constant name1 = "DogementorNFT";
    string constant name2 = "TurbopepeNFT";
    string constant symbol1 = "DOGE";
    string constant symbol2 = "PEPE";

    string constant name3 = "TURBO";
    string constant symbol3 = "TURBO";

    TurboNFT public immutable first;
    TurboNFT public immutable second;
    Turbo public immutable turbo;
    address public immutable feeReceiver;
    mapping(address => mapping(address => uint256)) public burned;
    mapping(address => mapping(address => bool)) public received;
    mapping(address => uint256) public firstTime;
    mapping(address => bool) nftProviders;
    mapping(address => bool) public pairStatus;

    constructor(
        address _feeReceiver,
        string memory _URIPrefix1,
        string memory _URISuffix1,
        string memory _URIPrefix2,
        string memory _URISuffix2
    ) ERC20(name0, symbol0) Ownable(msg.sender){
        feeReceiver = _feeReceiver;
        firstTime[address(0)] = 1;
        firstTime[msg.sender] = 1;
        firstTime[_feeReceiver] = 1;
        _mint(msg.sender, MAX_SUPPLY);
        first = new TurboNFT(name1, symbol1, _URIPrefix1, _URISuffix1, msg.sender, msg.sender);
        second = new TurboNFT(name2, symbol2, _URIPrefix2, _URISuffix2, msg.sender, msg.sender);
        turbo = new Turbo(name3, symbol3, msg.sender, TURBO_LIMIT);
        nftProviders[address(first)] = true;
        nftProviders[address(second)] = true;
    }

    function setPairStatus(address pair, bool status) public{
        _checkOwner();
        pairStatus[pair] = status;
    }

    function _update(
        address _from,
        address _to,
        uint256 _value
    ) internal override(ERC20) {
        if (nftProviders[_to]) {
            super._update(_from, address(0), _value);
            burned[_to][_from] += _value;
            if ((!received[_to][_from]) && (burned[_to][_from] >= THRESHOLD)) {
                received[_to][_from] = true;
                ITurboNFT provider = ITurboNFT(_to);
                provider.drop(_from);
            }
        } else {
            require (firstTime[_from] + COOLDOWN_OFFSET < block.timestamp, "Cooldown in progress");

            if (firstTime[_to] == 0){
                firstTime[_to] = block.timestamp;
            }
            if (pairStatus[_to]){
                require (_value < SELL_LIMIT, "Sell single transaction limit exceded");
            } else if (pairStatus[_from]){
                require (_value < BUY_LIMIT, "Buy single transaction limit exceded");
            }
            uint256 fee = (_value * 3) / 100;
            super._update(_from, feeReceiver, fee);
            super._update(_from, _to, _value - fee);
        }
    }
}
