// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/*
                ......
          .,;;##########::,.
       .;##''       ,/|  ``##;.
     .;#'         ,/##|__    `#;.
   .;#'          /######/'     `#;.
  ;#'             ,/##/__        `#;
 ;#'            ,/######/'        `#;
;#'            /######/'           `#;
;#'             ,/##/___           `#;
;#            ,/#######/'           #;
;#           /#######/'             #;
;#             ,/##/__              #;
`#;          ,/######/'            ;#'
`#;.        /######/'             ,;#'
 `#;.        ,/##/__             ,;#'
  `#;.      /######/'           ,;#'
    ##;_      |##/'           _;##
    :#`-;#;...|/'       ...;#;-'#:
    :`__ `-#### __  __ ####-' __':
    :  ``------.. `' ..------''  :
    `.. `--------`..'--------' ..'
      :                        :
      `:..      /:  :\      ..:'
         `.     ::  ::     .'
          #.              .#
          `'##;##;##;##;##`'
            `' `' `' `' `'
                                               (                        
 (                     )      (           (    )\ )               (     
 )\ )    (       )  ( /(   (  )\ )    (   )\  (()/(     (     )   )\ )  
(()/(    )(   ( /(  )\()) ))\(()/(   ))\ ((_)  /(_))   ))\ ( /(  (()/(  
 /(_))_ (()\  )(_))(_))/ /((_)/(_)) /((_) _   (_))_   /((_))(_))  ((_)) 
(_)) __| ((_)((_)_ | |_ (_)) (_) _|(_))( | |   |   \ (_)) ((_)_   _| |  
  | (_ || '_|/ _` ||  _|/ -_) |  _|| || || |   | |) |/ -_)/ _` |/ _` |  
   \___||_|  \__,_| \__|\___| |_|   \_,_||_|   |___/ \___|\__,_|\__,_|  
                                                                                    
*/


contract GratefulDead is Ownable, ERC721 {
    using ECDSA for bytes32;

    uint256 constant public DEADS_AMOUNT = 5556; // actually 5555
    uint256 public teamDeads = 250;
    uint256 public winnersDeads = 1500;
    uint256 public winnersPrice = 0.006 ether;
    uint256 public purgatoryPrice = 0.0069 ether;
    uint256 public publicPrice = 0.0075 ether;
    uint256 public mintDate = 1658109600; // 2022-07-18 2:00:00
    uint256 public maxPerWallet = 4; // actually 3
    uint256 public minted = 1;
    address public payoutAddress;
    string public baseTokenURI = "";
    string private _contractURI = "";

    address private _purgatorySignerAddress;
    address private _winnersSignerAddress;

    mapping(address => bool) public freeTaken;


    constructor(address payoutAddress_, address winnersSignerAddress_, address purgatorySignerAddress_)
        ERC721("GratefulDead", "DEAD")
    {
        payoutAddress = payoutAddress_;
        _purgatorySignerAddress = purgatorySignerAddress_;
        _winnersSignerAddress = winnersSignerAddress_;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function totalSupply() public view returns (uint256) {
        return minted - 1;
    }

    function publicMint(uint256 amount) external payable {
        uint256 _totalSupply = minted;
        require(block.timestamp > mintDate, "mint not started");
        require(msg.sender == tx.origin);
        require(
            _totalSupply + amount - 1 < DEADS_AMOUNT - teamDeads - (isWinnersReserved() ? winnersDeads : 0),
            "no more public tokens"
        );
        require(amount > 0, "too less");
        require(balanceOf(msg.sender) + amount < maxPerWallet, "too many");
        require(msg.value == publicPrice * amount, "wrong price");
        _mintMany(msg.sender, amount);
    }

    function purgatoryMint(uint256 amount, bytes calldata signature) external payable {
        uint256 _totalSupply = minted;
        require(block.timestamp > mintDate, "mint not started");
        require(_purgatorySignerAddress == keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            bytes32(uint256(uint160(msg.sender)))
        )).recover(signature), "signer address mismatch");
        require(msg.sender == tx.origin);
        require(
            _totalSupply + amount - 1 < DEADS_AMOUNT - teamDeads - (isWinnersReserved() ? winnersDeads : 0),
            "no more public tokens"
        );
        require(amount > 0, "too less");
        require(balanceOf(msg.sender) + amount < maxPerWallet, "too many");
        require(msg.value == purgatoryPrice * amount, "wrong price");
        _mintMany(msg.sender, amount);
    }

    function freeMintAndExtra(uint256 amount, bytes calldata signature) external payable {
        uint256 _totalSupply = minted;
        require(block.timestamp > mintDate, "mint not started");
        require(_winnersSignerAddress == keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            bytes32(uint256(uint160(msg.sender)))
        )).recover(signature), "signer address mismatch");
        require(msg.sender == tx.origin);
        require(
            _totalSupply + amount - 1 < DEADS_AMOUNT - teamDeads,
            "no more tokens"
        );
        require(amount > 0, "too less");
        require(balanceOf(msg.sender) + amount < maxPerWallet, "too many");
        uint256 freeAmount = freeTaken[msg.sender] ? 0 : 1;
        require(msg.value == (amount - freeAmount) * winnersPrice, "wrong price");
        _mintMany(msg.sender, amount);
        freeTaken[msg.sender] = true;
    }

    function freeMint(bytes calldata signature) external {
        uint256 _totalSupply = minted;
        require(block.timestamp >= mintDate, "mint not started");
        require(_winnersSignerAddress == keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            bytes32(uint256(uint160(msg.sender)))
        )).recover(signature), "signer address mismatch");
        require(msg.sender == tx.origin);
        require(
            _totalSupply < DEADS_AMOUNT - teamDeads,
            "no more tokens"
        );
        require(balanceOf(msg.sender) < maxPerWallet, "too many");
        require(!freeTaken[msg.sender], "free already minted");
        _mint(msg.sender, _totalSupply);
        _totalSupply++;
        minted = _totalSupply;
        freeTaken[msg.sender] = true;
    }

    function isWinnersReserved() public view returns (bool) {
        return (block.timestamp < (mintDate + 30 minutes));
    }

    function setReserved(uint256 _teamDeads, uint256 _winnerDeads) public onlyOwner {
        teamDeads = _teamDeads;
        winnersDeads = _winnerDeads;
    }

    function setMintDate(uint256 _mintDate) public onlyOwner {
        mintDate = _mintDate;
    }

    function setPrices(uint256 _winnersPrice, uint256 _purgatoryPrice, uint256 _publicPrice) public onlyOwner {
        winnersPrice = _winnersPrice;
        purgatoryPrice = _purgatoryPrice;
        publicPrice = _publicPrice;
    }

    function setSigners(address winnersSignerAddress_, address purgatorySignerAddress_) public onlyOwner {
        _winnersSignerAddress = winnersSignerAddress_;
        _purgatorySignerAddress = purgatorySignerAddress_;
    }

    function mintReserved(address to, uint256 amount) public onlyOwner {
        uint256 td = teamDeads;
        require(minted + amount - 1 < DEADS_AMOUNT, "no more tokens");
        require(td + 1 > amount, "no more reserved tokens");
        _mintMany(to, amount);
        teamDeads = td - amount;
    }

    function setPayoutAddress(address payoutAddress_) public onlyOwner {
        payoutAddress = payoutAddress_;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function _mintMany(address to, uint256 amount) internal virtual {
        uint256 _totalSupply = minted;
        for (uint256 i; i < amount; i++) {
            _mint(to, _totalSupply);
            _totalSupply++;
        }
        minted = _totalSupply;
    }

    function withdraw() public onlyOwner {
        payable(payoutAddress).transfer(address(this).balance);
    }
}