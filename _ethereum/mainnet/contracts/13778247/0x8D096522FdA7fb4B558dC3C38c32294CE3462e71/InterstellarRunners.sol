// contracts/InterstellarRunners
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract InterstellarRunners is
    ERC721,
    Ownable
{
    using SafeMath for uint256;

	enum WhitelistState { Unavailable, Available, Used }

    uint256 public constant loyalPrice = 25000000000000000;
    uint256 public constant regularPrice = 45000000000000000;
    uint256 public constant maxAddressMint = 80;
    uint256 public constant maxMultiPurchase = 20;
    string public constant provenanceHash = "C430C2DF45FF64845D60A0B4CCDE832813691947E9D732ABBCDA284CCE932AB1";

    uint256 public maxSupply = 4000;
	uint256 public totalSupply = 0;
    bool public allSalesComplete = false;
    bool public regularSaleInProgress = false;
	bool public whitelistSaleInProgress = false;
    mapping(address => WhitelistState) public whitelist;
	uint256 public availableWhitelistMints = 0;
    
	string private baseURI = "";

    constructor() ERC721("Interstellar Runners", "ALIENRUN") {}

    function mintRunner(uint256 numOfRunners) public payable {
        require(!allSalesComplete, "Sale has already ended");
        require(whitelistSaleInProgress || regularSaleInProgress, "Sale is not in progress");
        if (whitelistSaleInProgress) {
			require(
				whitelist[msg.sender] != WhitelistState.Unavailable,
				"Sale is only currently available to whitelisted addresses"
			);	
			require(
				numOfRunners == 1 && whitelist[msg.sender] == WhitelistState.Available,
				"Only 1 runner can be minted during the whitelist sale"
			);
		} else {
			require(
				numOfRunners > 0 && numOfRunners <= maxMultiPurchase,
				string(
					abi.encodePacked(
						"You can mint from 1 to ", 
						Strings.toString(maxMultiPurchase), 
						" runners per transaction"
					)
				)
			);
		}
        require(
            (balanceOf(msg.sender) + numOfRunners) <= maxAddressMint,
            string(
                abi.encodePacked(
                    "You can only mint ",
                    Strings.toString(maxAddressMint),
                    " runners per address. You currently have ",
                    Strings.toString(balanceOf(msg.sender))
                )
            )
        );
        require(
            (totalSupply + numOfRunners) <= maxSupply,
            "Quantity exceeds maximum supply"
        );    
		require(
			(
				whitelist[msg.sender] == WhitelistState.Available || 
				whitelist[msg.sender] == WhitelistState.Used
			) ?
				loyalPrice.mul(numOfRunners) <= msg.value :
				regularPrice.mul(numOfRunners) <= msg.value,
            "Not enough ether sent for this transaction"
		);
        
        for (uint256 i = 0; i < numOfRunners; i++) {
            uint256 runnerId = (totalSupply + 1);

            _safeMint(msg.sender, runnerId);

			totalSupply = runnerId;

            if (whitelist[msg.sender] == WhitelistState.Available) {
                whitelist[msg.sender] = WhitelistState.Used;
				availableWhitelistMints = (availableWhitelistMints - 1);
            }

            if (runnerId == maxSupply) {
                completeAllSales();
            }
        }
    }

    function mintGiveawayRunners(uint256 numOfRunners) public payable onlyOwner {
        require(!allSalesComplete, "Max supply already minted");
        require(
            (totalSupply + numOfRunners) <= maxSupply,
            "Quantity exceeds maximum supply"
        );

        for (uint256 i = 0; i < numOfRunners; i++) {
            uint256 runnerId = (totalSupply + 1);

            _safeMint(msg.sender, runnerId);

			totalSupply = runnerId;

            if (runnerId == maxSupply) {
                completeAllSales();
            }
        }
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

	function startWhitelistSale() public onlyOwner {
		whitelistSaleInProgress = true;
	}

	function pauseWhitelistSale() public onlyOwner {
		whitelistSaleInProgress = false;
	}

	function switchFromWhitelistToRegularSale() public onlyOwner {
		whitelistSaleInProgress = false;
		regularSaleInProgress = true;
	}

	function startRegularSale() public onlyOwner {
        regularSaleInProgress = true;
    }

	function pauseRegularSale() public onlyOwner {
        regularSaleInProgress = false;
    }

	function markAllSalesComplete() public onlyOwner {
        allSalesComplete = true;
    }

	function unmarkAllSalesComplete() public onlyOwner {
        allSalesComplete = false;
    }

	function completeAllSales() internal {
		whitelistSaleInProgress = false;
		regularSaleInProgress = false;
		allSalesComplete = true;
	}
	
    function addToWhitelist(address[] memory addresses) public onlyOwner {
		require(addresses.length > 0, "No addresses provided");

        for (uint256 i = 0; i < addresses.length; i++) {
            if (whitelist[addresses[i]] == WhitelistState.Unavailable) {
                whitelist[addresses[i]] = WhitelistState.Available;
				availableWhitelistMints = (availableWhitelistMints + 1);
            }
        }
    }

    function setWhitelistAddressState(address entry, WhitelistState state)
        public
        onlyOwner
    {
		if (
			whitelist[entry] == WhitelistState.Available &&
			state != WhitelistState.Available
		) {
			availableWhitelistMints = (availableWhitelistMints - 1);
		} else if (
			whitelist[entry] != WhitelistState.Available &&
			state == WhitelistState.Available
		) {
			availableWhitelistMints = (availableWhitelistMints + 1);
		}

        whitelist[entry] = state;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

	function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

	function getBaseURI()
        public
        view
        returns (string memory)
    {
		return baseURI;
	}

	function setBaseURI(string memory uri)
        public
		onlyOwner
    {
		baseURI = uri;
	}

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
