// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Allowlist.sol";
import "./SalesActivation.sol";

// ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+****+;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;+*******++;;;;;;*?%S##@@@@S;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;+#@@@@@@@@##S?%#%S#@@@@@@@@@#;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;+@@@@@@@@@@#@#%SS@@@##@@@@@@@+;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;%@@@@@@@@@@%*++*?%S#@@@@@@@@+;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;+S@@@@@@#%++++++++++**?%S##S+;;;;;**++;;;;;;;;;
// ;;;;;;;;;;;;;;;;*?+%@@#%*+++++++++++++++++++*%*;;;+****+;;;;;;;;
// ;;;;;;;;;;;;;;;*%+++++++++++++++++++++++++++++S%;;++*++;;;;;;;;;
// ;;;;;;;;;;;;;;;S++++++++++++++++++++++++;++++++S%;;;;++;;;;;;;;;
// ;;;;;;;;;;;;;;%%+++++++++;++*?+++++++??++++***?*#*;;;;+;;;;;;;;;
// ;;;;;;;;;;;;;+#++++++++++++%S*+*****??*+*++++;%*?#;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;%%++++++++++?%+:++++;;::,,,:;+;,,;S+#*;;;;;;;;;;;;;
// ;;;;;;;;;;;;;#*+++++++*%%+,,,:;;;;;;;++++;:,,,,*%%%;;;;;;;;;;;;;
// ;;;;;;;;;;;;*#+++***??*S;,,,,,;;::::::,,,:;;::,:S%S;;;;;;;;;;;;;
// ;;;;;;;;;;;;S%++%++%*:,%:,,,,,:*%*,,,,;+++*++++;?S%;;;;;;;;;;;;;
// ;;;;;;;;;;;+#*+*?,:?+:,%:,,,,:+;::,,,:*;;;;;;;;++;*+;;;;;;;;;;;;
// ;;;;;;;;;;;*#++S*,,*?::%:,,,;++;,,:::;*?+:+*+;+*;:;?;;;;;;;;;;;;
// ;;;;;;;;;;;%S++#;,,*;,:%,,,,::::,,:;;;*?+:+*+;;::;:?+;;;;;;;;;;;
// ;;;;;;;;;;;#?+*#:,,:,,:%,,,,,:::,,,,,,;*;;;+++;;;::I+;;;;;;;;;;;
// ;;;;;;;;;;+@*+%S:,,,,,:%,,+*%S#S?+:::;+?**+;+;;:::;%;;;;;;;;;;;;
// ;;;;;;;;;;*@+*%@%+;;::,%*%#@@@@@@#S?++;::::::;;+++%*;;;;;;;;;;;;
// ;;;;;;;;;;?#+*L@@@@##S%#@@@@@#????+;:::;;;:+**++;;C*;;;;;;;;;;;;
// ;;;;;;;;;;%S+*S@@@@@@@@@+::;S?**%?+:;;;;;:;%:,,,,,??;;;;;;;;;;;;
// ;;;;;;;;;;S?+*S@@@@@@@@@+,,,,::+%::;;;;;;;;%+:,,,,*?;;;;;;;;;;;;
// ;;;;;;;++;#?+*U@@@@@@@@@?,,,:;*?;:;;;;;;;;:;****++H?;;;;;;;;;;;;
// ;;;;;**+**S??%#@@@@####@S++**+;::;:;;;;;;;;;::;;;*@?;;;;;;;;;;;;
// ;;;;;%+**++*++K@@@%*;;;+?*;;:::;;;;;;;;;;;;;;;;:;#@%*+;;;;;;;;;;
// ;;;;;?*::::+?%#@@@@#S?****+:;;;;;;;;;;;;;;;;;::*#@@@@#?;;;;;;;;;
// ;;;;;;?*++**++%#######?;;;;;;;;;;;;;;;;;;:::;*I@@@##S%*;;;;;;;;;
// ;;;;;;;+??+:::+?%%S###@S%+;:::::::::::;;;+*?S#@#@###%*;;;;;;;;;;
// ;;;;;;;;;+*?%?E+;:%%%%%%?+***********??%%%%%########@#*;;;;;;;;;

contract GoingNuts is ERC721A, Allowlist, SalesActivation{

    using Strings for uint256;

    // base URI
    string private baseTokenURI;
    // Price of each nuts
    uint256 public og_price = 0.04 ether;
    uint256 public wl_price = 0.05 ether;
    uint256 public price = 0.08 ether;
    // Maximum amount of nuts in existance 
    uint256 public max_sales_nuts = 10000;
    // For giveaway 
    uint256 public team_mint = 200;
    // Max presale 
    uint256 public og_max = 100;
    uint256 public og_purchased = 0;
    uint256 public presale_period_purchased = 0;
    uint256 public presale_period_phase_max = 1000;
    uint256 public max_per_wallet = 2;
    // OG claimed
    mapping(address => bool) public og_list;
    mapping(address => uint256) public ogListBought;
    // Presale claimed
    address[] public addressesOfPresaleBought;
    mapping(address => uint256) public presaleListBought;
    // team addresses
    address public nuts_wallet = 0xf2EC318ab1b7C1019B1D957B48E4E5b082d340E3;
    //Event presale
    event Presale(uint256 quantity, address buyer);
    
    constructor(string memory tokenURI, address sign_address,
    uint256 _publicSalesStartTime, uint256 _preSalesStartTime, uint256 _preSalesEndTime, 
    uint256 _ogSalesStartTime, uint256 _ogSalesEndTime) 
    ERC721A("Going Nuts", "NT") Allowlist("GoingNuts","1",sign_address) 
    SalesActivation(_ogSalesStartTime,_ogSalesEndTime,_publicSalesStartTime,
    _preSalesStartTime,_preSalesEndTime) {
        setBaseURI(tokenURI);
    }

    /**
    * @dev OG sales nuts
    */
    function ogSale(uint256 nutsNumber) public payable isOGSalesActive {
        uint256 supply = totalSupply();
        require(og_list[msg.sender], 'You are not on the OG list');
        require(og_purchased + nutsNumber <= og_max, 'Purchase exceeds max allowed');
        require( msg.value >= og_price * nutsNumber,             "Ether sent is not correct" );
        require( supply + nutsNumber <= max_sales_nuts - team_mint,      "Exceeds maximum nuts supply" );
        require(ogListBought[msg.sender] + nutsNumber <= max_per_wallet, 'Purchase exceeds max allowed');
        require(tx.origin == msg.sender, "Contracts not allowed to mint");
        // og spot bought
        _safeMint(msg.sender, nutsNumber);
        ogListBought[msg.sender] += nutsNumber;
        // increment purchased og numbers
        og_purchased += nutsNumber;
    }

    /**
    * @dev Presale nuts
    */
    function presale(uint256 nutsNumber, bytes memory _signature) public payable isPreSalesActive isSenderAllowlisted(nutsNumber, _signature){
        uint256 supply = totalSupply();
        require( presale_period_purchased + nutsNumber <= presale_period_phase_max - og_max, 'Exceeds presale nuts supply');
        require( supply+nutsNumber <= max_sales_nuts - team_mint,      "Exceeds maximum nuts supply" );
        require(presaleListBought[msg.sender] + nutsNumber <= max_per_wallet, 'Purchase exceeds max allowed');
        require( msg.value >= wl_price * nutsNumber,             "Ether sent is not correct" );
        require(tx.origin == msg.sender, "Contracts not allowed to mint");

        _safeMint(msg.sender, nutsNumber);
        // increment purchased wl numbers
        presale_period_purchased += nutsNumber;
        presaleListBought[msg.sender] += nutsNumber;
        addressesOfPresaleBought.push(msg.sender);
        emit Presale(nutsNumber, msg.sender);
    }

    /**
    * @dev Mint nuts
    */
    function mint(uint256 nutsNumber) public payable isPublicSalesActive {
        uint256 supply = totalSupply();
        require( msg.value >= price * nutsNumber,             "Ether sent is not correct" );
        require( presale_period_purchased + nutsNumber <= presale_period_phase_max - og_purchased,      "Exceeds maximum period nuts supply" );
        require( supply+nutsNumber <= max_sales_nuts - team_mint,      "Exceeds maximum nuts supply" );
        require(nutsNumber > 0, "You cannot mint 0 nuts.");
        require(nutsNumber <= 5, "You are not allowed to buy this many nuts at once.");
        require(tx.origin == msg.sender, "Contracts not allowed");

        _safeMint( msg.sender, nutsNumber);
        presale_period_purchased += nutsNumber;
    }

    /**
    * @dev Owner Mint nuts
    */
    function ownerMint(address _to,uint256 nutsNumber) external onlyOwner() {
        uint256 supply = totalSupply();
        require( supply+nutsNumber <= max_sales_nuts,      "Exceeds maximum nuts supply" );

        _safeMint(_to, nutsNumber);
        team_mint -= nutsNumber;
    }
    

    /**
    * @dev Change the base URI when we move IPFS (Callable by owner only)
    */
    function setBaseURI(string memory _uri) public onlyOwner {
        baseTokenURI = _uri;
    }
    
    /**
    * @dev Change the max team mint
    */
    function setTeamMint(uint256 _max_number) public onlyOwner {
        team_mint = _max_number;
    }

    /**
    * @dev Set OG Max Number
    */
    function setOGMax(uint256 _max_number) public onlyOwner {
        og_max = _max_number;
    }

    /**
    * @dev Change the og purchased number
    */
    function setOGPurchased(uint256 _number) public onlyOwner {
        og_purchased = _number;
    }

    /**
    * @dev Change the Pre Sales Max
    */
    function setPreSalesMax(uint256 _max_number) public onlyOwner {
        presale_period_phase_max = _max_number;
    }

    /**
    * @dev Change the presale purchased number
    */
    function setPreSalesPurchased(uint256 _max_number) public onlyOwner {
        presale_period_purchased = _max_number;
    }

    /**
    * @dev Change the total Sales nuts
    */
    function setTotalSalesnuts(uint256 _totalnuts) public onlyOwner {
        max_sales_nuts = _totalnuts;
    }

    /**
    * @dev Change the presale list max number
    */
    function setMaxPerWallet(uint256 _max_per_wallet) public onlyOwner {
        max_per_wallet = _max_per_wallet;
    }


    /**
    * @dev Add people to OG List
    */
    function addToOGList(address[] calldata _og_list) public onlyOwner {
        for (uint256 i = 0; i < _og_list.length; i++) {
            og_list[_og_list[i]] = true;
            ogListBought[_og_list[i]] > 0 ? ogListBought[_og_list[i]] : 0;
        }
    }

    /**
    * @dev Remove people from OG List
    */
    function removeFromOGList(address[] calldata removeList) public onlyOwner {
        for (uint256 i = 0; i < removeList.length; i++) {
            og_list[removeList[i]] = false;
        }
    }

    /**
    * @dev Reset the presale list
    */
    function resetPresaleListBought() public onlyOwner {
        for (uint i=0; i< addressesOfPresaleBought.length ; i++){
            presaleListBought[addressesOfPresaleBought[i]] = 0;
        }
        delete addressesOfPresaleBought;
    }

    /**
    * @dev Set Price if need to discount (Callable by owner only)
    */
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    /**
    * @dev Set Price if need to discount (Callable by owner only)
    */
    function setWhitelistPrice(uint256 _newPrice) public onlyOwner {
        wl_price = _newPrice;
    }

    /**
    * @dev Set Price if need to discount (Callable by owner only)
    */
    function setOGPrice(uint256 _newPrice) public onlyOwner {
        og_price = _newPrice;
    }

    /**
    * @dev Set Team wallet
    */
    function setTeamWallet(address _newWallet) public onlyOwner {
        nuts_wallet = _newWallet;
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint256 _balance = address(this).balance;
        require(payable(nuts_wallet).send(_balance));
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}
