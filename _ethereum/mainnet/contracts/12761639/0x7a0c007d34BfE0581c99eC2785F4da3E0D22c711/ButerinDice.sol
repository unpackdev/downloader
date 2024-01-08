//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";

interface IGameItem {
    function awardItem(address player, string memory tokenURI)
    external
    returns (uint256);
}

interface IBDToken {
    function approve(address _spender, uint256 _value) 
    external 
    returns (bool success);
    function allowance(address _owner, address _spender) 
    view 
    external 
    returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) 
    external 
    returns (bool success);
    function totalSupply() 
    view 
    external 
    returns (uint256);
}

contract ButerinDice is ReentrancyGuard {
    IGameItem nft;
    IBDToken bdt;
    address payable owner;
    address payable collector1;
    address payable collector2;
    address payable collector3;
    uint public blockNumber;
    uint256 public gamesPlayed;
    uint256 public winners;
    uint256 public losers;
    bytes32 public blockHashNow;
    bytes32 public blockHashPrevious;

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    constructor() {
        //nft = IGameItem(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        //bdt = IBDToken(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
        nft = IGameItem(0x6c8F47d3bb4eE19778A303064087b18BDE870c5e);
        bdt = IBDToken(0xA2f25ed17c37788495A6Caa78DCd678E8b893C92);
        owner = payable(msg.sender);
        collector1 = payable(0x67a9Ce63403370e2C6C02Ed596105F6ffBeff9B8);
        collector2 = payable(0x8AFb5ec02ac1E57c5e8d3a5422D73809d4630f1D);
        collector3 = payable(0x35c156911700e5B1BAD54BCA5dADb276D3EcFcF1);
    }

    event EthReceived(
        address indexed _from,
        uint _value
    );

    event GameOver(
        address indexed _from,
        uint _value,
        bool winner,
        uint nftId
    );

    function totalGamesPlayed() public view returns(uint256){
        return gamesPlayed;
    }

    function totalWinners() public view returns(uint256){
        return winners;
    }

    function totalLosers() public view returns(uint256){
        return losers;
    }

    function MergeBytes(bytes memory a, bytes memory b) private pure returns (bytes memory c) {
        uint alen = a.length;
        uint totallen = alen + b.length;
        uint loopsa = (a.length + 31) / 32;
        uint loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            mstore(m, totallen)
            for {  let i := 0  } lt(i, loopsa) { i := add(1, i)  } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i)))))  }
            for {  let i := 0  } lt(i, loopsb) { i := add(1, i)  } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i)))))  }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }

    function splitBytes(bytes32 r) private pure returns (bytes16 i, bytes16 j) {
        assembly {
            i := r
            j := shl(128, r)
        }
    }

    function payCollectors() private nonReentrant {
            (bool sentCollector1, ) = collector1.call{value: (msg.value * 3)/100}("");
            (bool sentCollector2, ) = collector2.call{value: (msg.value * 2)/100}("");
            (bool sentCollector3, ) = collector3.call{value: (msg.value * 1)/100}("");
            require(sentCollector1, "failed to send ether");
            require(sentCollector2, "failed to send ether");
            require(sentCollector3, "failed to send ether");
    }

    function payWinner(address _to, uint value) private {
        gamesPlayed = gamesPlayed + 1;
        uint nftId = 0;
        bytes memory newOwner = abi.encode(owner, value, winners, tx.origin);
        bytes memory sender = abi.encode(msg.sender, address(this).balance, losers, msg.sig);
        bytes memory rightNow = abi.encode(block.timestamp, block.difficulty, block.number, block.coinbase, gamesPlayed);
        blockNumber = block.number;
        blockHashNow = blockhash(blockNumber);
        blockHashPrevious = blockhash(blockNumber - 1);
        bytes memory hashInput = MergeBytes(
            MergeBytes(newOwner, rightNow),
            MergeBytes(sender, rightNow)
        );
        bytes memory finalShuffle = MergeBytes(
            hashInput,
            bytes(abi.encode(blockHashNow, blockHashPrevious))
        );
        bytes32 ticket = keccak256(finalShuffle);
        (bytes16 playerOne, bytes16 playerTwo) = splitBytes(ticket);
        if(playerOne > playerTwo){
            uint newValue = value * 2 - (value *  6)/100;
            if(value > address(this).balance / 10 - value) {
                nftId = nft.awardItem(_to, "https://mocki.io/v1/dbe92b20-2b63-4722-8b0a-b77814c57759");
            }
            if(gamesPlayed % 10 == 0){
                bdt.allowance(owner,  address(this));
                bdt.approve(address(this), 10 * 10 ** 18);
                bdt.transferFrom(address(this), msg.sender, 10 * 10 ** 18);
            }
            (bool sent, ) = _to.call{value: newValue}("");
            payCollectors();
            emit GameOver(_to, newValue, true, nftId);
            winners = winners + 1;
            require(sent, "failed to send ether");
        } else {
            payCollectors();
            emit GameOver(_to, value, false, 0);
            losers = losers + 1;
        }
    }

    function destruir() public onlyOwner returns(bool){
        selfdestruct(owner);
        return true;
    }

    function withdraw(uint amount) public onlyOwner nonReentrant returns(bool) {
        require(amount <= address(this).balance);
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "failed to send ether");
        return sent;
    }

    receive() external payable {
        if(msg.sender == owner){
            require(msg.sender == owner, "contract funded");
        } else if (msg.value <= address(this).balance / 10) {
            payWinner(msg.sender, msg.value);
            bdt.allowance(owner,  address(this));
            bdt.approve(address(this), 1 * 10 ** 18);
            bdt.transferFrom(address(this), msg.sender, 1 * 10 ** 18);
        } else {
            revert("Try placing a lower bet");
        }
        emit EthReceived(msg.sender, msg.value);
    }

}
