// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC721.sol";

contract NetworkStateGenesis is ERC721, Ownable {
    string public GENESIS; // Preserving consciousness of the moment
    string public _tokenURI;
    uint256 public currentPrice = 7 * (10 ** 16); // Starting price is 0.07 ETH
   	uint256 public currentSerialNumber = 128; // Numbers 0-127 are reserved for Elon, Pope, Obama, Putin, Lady Gaga, Zuck, Bezos, Draper, Diamandis, Jack, Sergey, Larry, Schmidt, Dalai Lama, Buffet, Vitalik... (you get the idea)
    uint256 public cutoffTimestamp;  // Initially all have the same price. Later on (1625443200 ---> 2021-07-05T00:00:00.000Z) the 0.1% increase kicks in
  	uint256 public multiplier = 1001; 
  	uint256 public divisor = 1000; // Doing math in ETH. Multiply by 1001. Divide by 1000. Effectively 0.1% increase with each purchase
  	event Purchase(address indexed addr, uint256 indexed currentSerialNumber, uint256 price, bool BTC); // Final parameter `BTC` to indicate if purchase with BTC
    address public WBTCaddress; // On mainnet: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    IERC20 private WBTC; // Instantiating WBTC contract to call `transferFrom` when purchasing with WBTC
    address payable public multisig; // Ensure you are comfortable with m-of-n signatories on Gnosis Safe (don't trust, verify)

    constructor(string memory name, string memory symbol, address payable _multisig, address _WBTCaddress, uint _cutoffTimestamp) ERC721(name, symbol) {
        require(_multisig != address(0), "multisig has be set up");
        require(_WBTCaddress != address(0), "WBTC has be set up");

        multisig = _multisig;
        cutoffTimestamp = _cutoffTimestamp;
        WBTCaddress = _WBTCaddress;
        WBTC = IERC20(WBTCaddress);

        for (uint i=0; i<128; i++) {
            _mint(multisig, i); 
        }
    }

    // 1. Deploy 2. Include the smart contract address in the PDF. 3. Save IPFS has in this method.
    function setGenesis(string memory IPFSURI) public onlyOwner {
        require(bytes(GENESIS).length == 0, "GENESIS can be set only once"); // https://ethereum.stackexchange.com/a/46254/2524
        GENESIS = IPFSURI;
    }

    function setTokenURI(string memory URI) public onlyOwner {
        require(bytes(_tokenURI).length == 0, "_tokenURI can be set only once");
        _tokenURI = URI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURI;
    }
 
    receive() external payable { // Fallback function
        purchase();
    }

    function purchase() payable public {
        require(msg.value >= currentPrice, "Not enough ETH. Check the current price.");
        uint256 refund = msg.value - currentPrice;
        if (refund > 0) {
            (bool sent1, bytes memory data1) = payable(msg.sender).call{value: refund}("");
            require(sent1, "Failed to send ETH refund to the sender");
        }       

        // Sending to Gnosis Safe takes more than 21k gas limit on `transfer`
        // Need to use something else, see: https://solidity-by-example.org/sending-ether/
        (bool sent2, bytes memory data2) = multisig.call{value: currentPrice}("");
        require(sent2, "Failed to send ETH to the multisig");

        _mint(msg.sender, currentSerialNumber);
        emit Purchase(msg.sender, currentSerialNumber, currentPrice, false);
        currentSerialNumber++;

        if (block.timestamp > cutoffTimestamp) {
            currentPrice = currentPrice * multiplier / divisor; // * 1001 / 1000 === increase by 0.1% (no longer SafeMath, compiler by default)
        }
    }

    // This is inspired by Hackers Congress Paralelní Polis: final ticket available for 1 BTC
    // Network State Genesis offers *UNLIMITED* number of NFTs for 1 BTC
    // How is that even possible?
    // As we establish multiplanetary civilisation, some of the accrued money will be put back into the circulation (Bitcoin recycling)
    function purchaseWithWBTC() public {
        WBTC.transferFrom(msg.sender, multisig, 10 ** 18);
        _mint(msg.sender, currentSerialNumber);
        Purchase(msg.sender, currentSerialNumber, 0, true);
        currentSerialNumber++;
    }

    // ALWAYS FREE (only the gas fee) and available to everyone. Free claim as opposed to the actual purchase.
    // BUT: if someone can afford to send a transaction on ETH, they surely can afford 0.07 ETH? (not 100% sure if `free claim` is really needed)
    // TODO: cross-check with proof of humanity (sybil attack) and store signature off-chain
    // We do not know yet, probably there will be some airdrop to all the citizens? TBD. TBC.
    event FreeClaim(address indexed addr);
    mapping(address => uint) public registrationTime;
    
    function freeClaim() public {
        require(registrationTime[msg.sender] == 0, "Address already registered");
        registrationTime[msg.sender] = block.timestamp;
        emit FreeClaim(msg.sender);
    }

    // On-chain interface for communication
    // Naturally, there will be off-chain solutions as well
    event MessagePosted(string IPFShash, address author);
    mapping(address => string[]) public messages;

    function publishMessage(string memory IPFShash) public {
        string[] memory messagesUser = messages[msg.sender];
        if (messagesUser.length == 0) {
            messages[msg.sender] = [IPFShash];
        } else {
            messages[msg.sender].push(IPFShash);
        }

        emit MessagePosted(IPFShash, msg.sender);
    }

    // Need to have decidated function, see: https://ethereum.stackexchange.com/a/20838/2524
    function getMessagesLength(address addr) public view returns(uint256) {
        return messages[addr].length;
    }
}