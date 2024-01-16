    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.7;
    
//    ___     ____ 
//   / _ \   / ___|
//  | | | | | |  _ 
//  | |_| | | |_| |
//   \___/   \____|
    
    import "./ERC721.sol";
    import "./ERC721Enumerable.sol";
    import "./Counters.sol";
    import "./PaymentSplitter.sol";
    import "./Ownable.sol";
    import "./Strings.sol";
    import "./ReentrancyGuard.sol";

    contract OG is ERC721Enumerable, PaymentSplitter, Ownable, ReentrancyGuard {

        //To increment the id of the NFTs
        using Counters for Counters.Counter;

        using Strings for uint256;

        //Id of the next NFT to mint
        Counters.Counter private _nftIdCounter;

        //The different stages of selling the collection
        enum Steps {
            Before,
            FreeMint,
            Sale,
            SoldOut,
            Reveal
        }


        string public baseURI;

        string public notRevealedURI;

        bool public revealed = false;

        Steps public sellingStep;

        //Number of NFTs in the collection
        uint public constant MAX_SUPPLY = 1993;
        uint private constant MAX_FREEMINT = 993;
        uint private constant MAX_SALE = 947;
        uint private constant MAX_GIFT = 52;
        //Maximum number of NFTs an address can mint
        uint private constant MAX_PER_ADDRESS = 1;
        //Price of one NFT in sale
        uint public priceSale = 0.01 ether;

        uint public saleStartTime = 1663430400;

        //Keep a track of the number of tokens per address
        mapping(address => uint) nftsPerWallet;

        uint private teamLength;
        address [] private _team = [
            0x485f728a9fDaD1730857eA96fD5De692c3baAeD9,
            0xCfDA2c868e82778E288Ad5CDFEeF3171f23bD65c
        ];
        uint[] private _teamShares = [
            20,
            80
        ];

        //Constructor of the collection
        constructor(string memory _theBaseURI, string memory _notRevealedURI) ERC721("Original Gangster", "OG") PaymentSplitter(_team, _teamShares) {
            _nftIdCounter.increment();
            baseURI = _theBaseURI;
            notRevealedURI = _notRevealedURI;
            teamLength = _team.length;
        }

        modifier callerIsUser() {
            require(tx.origin == msg.sender, "The caller is another contract");
            _;
        }
        

        function freeMint(address _account, uint256 _ammount) external nonReentrant callerIsUser {
            uint numberNftSold = totalSupply();
            require(currentTime() >= saleStartTime, "Wait !");
            require(sellingStep == Steps.FreeMint, "that's not the moment yet");
            require(numberNftSold + _ammount <= MAX_FREEMINT, "No more Free Mints.");
            require(nftsPerWallet[msg.sender] + _ammount <= MAX_PER_ADDRESS, "Only 1 OG, u should leave now !");
            //Increment the number of NFTs this user minted
            nftsPerWallet[msg.sender] += _ammount;
            //Mint the user NFT
            _safeMint(_account, _nftIdCounter.current());
            //Increment the Id of the next NFT to mint
            _nftIdCounter.increment();
            if(numberNftSold + _ammount == MAX_FREEMINT) {
                sellingStep = Steps.Sale;   
            }
        }

        function saleMint(address _account, uint256 _ammount) external payable nonReentrant callerIsUser{
            //Get the number of NFT sold
            uint numberNftSold = totalSupply();
            //Get the price of one NFT in Sale
            uint price = priceSale;
            //If everything has been bought
            require(sellingStep != Steps.SoldOut, "That's a Sold Out.");
            //If Sale didn't start yet
            require(sellingStep == Steps.Sale, "Wait ! sale has not started yet.");
            //Did the user then enought Ethers to buy ammount NFTs ?
            require(msg.value >= price * _ammount, "Not enought funds.");
            require(numberNftSold + _ammount <= MAX_SALE + MAX_FREEMINT, "No OG available.");
            require(nftsPerWallet[msg.sender] + _ammount <= MAX_PER_ADDRESS, "Only 1 OG, u should leave now !");
            //Increment the number of NFTs this user minted
            nftsPerWallet[msg.sender] += _ammount;
            //Mint the user NFT
            _safeMint(_account, _nftIdCounter.current());
            //Increment the Id of the next NFT to mint
            _nftIdCounter.increment();
            if(numberNftSold + _ammount == MAX_SALE + MAX_FREEMINT) {
                sellingStep = Steps.SoldOut;   
            }
        }

        function setSaleStartTime(uint _saleStartTime) external onlyOwner {
            saleStartTime = _saleStartTime;
        }

        function setBaseUri(string memory _baseURI) external onlyOwner {
            baseURI = _baseURI;
        }

        function currentTime() internal view returns(uint) {
            return block.timestamp;
        }

        function setStep(uint _step) external onlyOwner {
            sellingStep = Steps(_step);
        }

        function reveal() external onlyOwner{
            revealed = true;
        }

        function gift(address _account, uint _quantity) external onlyOwner {
            uint supply = totalSupply();
            require(supply + _quantity <= MAX_FREEMINT + MAX_SALE + MAX_GIFT, "Sold out");
            _safeMint(_account, _quantity);
        }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
            require(_exists(_tokenId), "URI query for nonexistent token");
            if(revealed == false) {
                return notRevealedURI;
            }

            return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
        }

        //ReleaseALL
        function releaseAll() external {
            for(uint i = 0 ; i < teamLength ; i++) {
                release(payable(payee(i)));
            }
        }

        receive() override external payable {
            revert('Only if you mint');
        }

    }