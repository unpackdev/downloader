import "./StonesUtils.sol";

pragma solidity ^0.6.12;

contract Stones is ERC721, Ownable {

    //NFTs are movable 1 week after contract deployment
    uint public transfersUnlockedAt;

    function claimedInfo() public view returns (uint[] memory) {
        return claimed;
    }

    constructor() public ERC721("Stones", "STONES") {
        _setBaseURI("https://nft.deworld.org/describe/");
        transfersUnlockedAt = block.timestamp + 604800;
    }

    function migrateNFTMetaData(string memory _base) public onlyOwner {
        _setBaseURI(_base);
    }

    uint public curveX = 100;
    uint[] public claimed;
    mapping(uint => bool) public isClaimed;

    function calcPrice(uint _Id) public view returns (uint256) {
        // LINK Stone (Chainlink capabilities)
        if (_Id >= 0 && _Id < 50) {
            return (5 ether *curveX/100);
        }

        // UNI Stone (Uniswap capabilities)
        if (_Id >= 50 && _Id < 200) {
            return(1 ether *curveX/100);
        }

        // COMP Stone (Compound capabilities)
        if (_Id >= 200 && _Id < 270) {
            return(3 ether *curveX/100);
        }

        // AAVE Stone (AAVE capabilities)
        if (_Id >= 270 && _Id < 340) {
            return(3 ether *curveX/100);
        }

        // DAI Stone (Maker SAI/DAI capabilities)
        if (_Id >= 340 && _Id < 440) {
            return(1 ether *curveX/100);
        }

        // YFI Stone (Yearn capabilities)
        if (_Id >= 440 && _Id < 540) {
            return(2 ether *curveX/100);
        }

        // PROMINT Stone (DeFi Mint capabilities)
        if (_Id >= 540 && _Id < 620) {
            return(6 ether *curveX/100);
        }

        // HUT (full access to DeWorld)
        if (_Id >= 620 && _Id < 1420) {
            //0.2 eth
            return(2e17*curveX/100);
        }

    }

    function claimStone(uint _Id) public payable returns (uint256)
    {
        require(_Id < 1420, "id");
        require(isClaimed[_Id] == false, "claimed");

        uint requiredValue = calcPrice(_Id);
        require(msg.value == requiredValue, "mispriced");
        require(block.timestamp < transfersUnlockedAt, "over");

        _mint(msg.sender, _Id);
        claimed.push(_Id);
        isClaimed[_Id] = true;
        //bump NFT up BC price up 3%;
        curveX = curveX + 3;
        return _Id;
    }

    function claimETH() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    //lock transfers for 2 weeks from the moment of deployment
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        require(transfersUnlockedAt < block.timestamp || _from == address(0), "distribution");
    }
}
