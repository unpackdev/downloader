// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //>=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract OnChainAsciiApes is ERC721Enumerable, Ownable, ReentrancyGuard {
    /*
OnChainAsciiApes - fully onchain, randomly assigned - living on the eth chain now and forever
                  ██████████████
                 ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓████
               ████▓▓▓▓▓▓░░░░▓▓▓▓░░██
             ██▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░██
             ██▓▓▓▓▓▓░░░░░░₿░░░░░Ξ░░░██
             ██▓▓██▓▓░░██░░░░░░░░░░░░░░██
               ██▓▓▓▓██░░░░░░░░░░░░░░░░░░██
   ██████        ██▓▓██░░░░░░░░████░░░░░░██
 ██▓▓▓▓▓▓██        ██░░████████░░░░██████
██▓▓▓▓▓▓▓▓▓▓██      ████░░░░░░░░░░░░░░██      
██▓▓▓▓██▓▓▓▓██    ██▓▓▓▓██████████████        
██▓▓▓▓▓▓██████████▓▓▓▓▓▓▓▓▓▓██▓▓▓▓██        
 ██▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓██▓▓▓▓██▓▓▓▓██    
   ████████████▓▓▓▓▓▓▓▓▓▓██▓▓▓▓██▓▓▓▓██    
             ██████████▓▓██░░░░░░██░░░░██
           ██░░░░░░░░░░██░░░░░░██░░░░██
           ██████████████████████████
 */

    address s_accessControlContractAddress;
    ApeGeneratorImpl apeGenerator;
    bool s_publicMintActive;

    using Counters for Counters.Counter;

    Counters.Counter private tokensAlreadyMinted;
    uint256 private lastGetRandomNumber;

    uint256 mintPriceWei;

    constructor(
        address _apeGeneratorContractAddress,
        address _accessControlContractAddress,
        uint256 _mintPriceWei
    ) ERC721("OnChainAsciiApes", "OCAA") {
        lastGetRandomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    blockhash(block.number - 1),
                    block.timestamp
                )
            )
        );

        mintPriceWei = _mintPriceWei;

        //link other contracts
        linkApeGenerator(_apeGeneratorContractAddress);

        s_accessControlContractAddress = _accessControlContractAddress;
    }

    function endMint() public onlyOwner {
        apeGenerator.endMintReduceTotalSupply(
            uint8(tokensAlreadyMinted.current())
        );
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "contract balance=0");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return (address(this).balance);
    }

    function checkIfWhitelisted(address _addressToBeChecked)
        public
        view
        returns (bool)
    {
        accessControlImpl accessControl = accessControlImpl(
            s_accessControlContractAddress
        );
        return (accessControl.isAccessGranted(_addressToBeChecked));
    }

    function enablePublicMint() public onlyOwner {
        s_publicMintActive = true;
    }

    function totalSupply() public view override returns (uint256) {
        return (apeGenerator.totalSupply());
    }

    function getNrOfLeftTokens() public view returns (uint256) {
        return (apeGenerator.totalSupply() - tokensAlreadyMinted.current());
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return apeGenerator.getTokenURI(uint8(_tokenId));
    }

    function createRandomNumber() private returns (uint256) {
        lastGetRandomNumber = uint256(
            (
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        blockhash(block.number - 1),
                        block.timestamp,
                        lastGetRandomNumber
                    )
                )
            )
        );

        return lastGetRandomNumber;
    }

    function createRandomNumberInRange(uint8 _range) private returns (uint8) {
        return uint8(createRandomNumber() % _range);
    }

    function linkApeGenerator(address _apeGeneratorContractAddress)
        public
        onlyOwner
    {
        require(
            _apeGeneratorContractAddress != address(0),
            "apeGenerator contract address invalid"
        );
        apeGenerator = ApeGeneratorImpl(_apeGeneratorContractAddress);
    }

    function mint(uint256 _wantedQuantity) public payable nonReentrant {
        // pre work for mint - start
        require(getNrOfLeftTokens() > 0, "minted out, check secondary market");
        require(
            _wantedQuantity > 0 &&
                _wantedQuantity <= 8 &&
                getNrOfLeftTokens() >= _wantedQuantity,
            "invalid quantity"
        );
        require(
            msg.value >= _wantedQuantity * mintPriceWei,
            "Sent eth amount too low"
        );
        for (uint256 i = 0; i < _wantedQuantity; i++) {
            require(createAssignMint(), "mint failed");
        }
    }

    function createAssignMint() private returns (bool success) {
        if (
            !s_publicMintActive ||
            tokensAlreadyMinted.current() >= totalSupply() - 3
        ) {
            //check if access is granted, either per wl or last 3 tokens for highest donators
            require(checkIfWhitelisted(msg.sender), "not whitelisted");
        }

        uint8 randomCreatedMintCombinationIndex;
        uint8 currentTokenId = uint8(tokensAlreadyMinted.current());
        uint8 specialApeIndex = apeGenerator.getSpecialApeIndex(currentTokenId);
        string memory apeGeneratorErrorMessage = "apeGen failed";
        if (specialApeIndex != totalSupply() + 1) {
            require(
                apeGenerator.registerApe(
                    specialApeIndex,
                    0,
                    0,
                    0,
                    currentTokenId,
                    0,
                    (60 + createRandomNumberInRange(40))
                ),
                apeGeneratorErrorMessage
            );
        } else {
            randomCreatedMintCombinationIndex = createRandomNumberInRange(
                apeGenerator.nrOfAvailableMintCombinations()
            );
            require(
                apeGenerator.registerApe(
                    specialApeIndex,
                    randomCreatedMintCombinationIndex,
                    createRandomNumberInRange(3),
                    createRandomNumberInRange(3),
                    currentTokenId,
                    createRandomNumberInRange(13),
                    (60 + createRandomNumberInRange(40))
                ),
                apeGeneratorErrorMessage
            );
        }

        _safeMint(msg.sender, currentTokenId);

        if (specialApeIndex == totalSupply() + 1) {
            apeGenerator.removeMintCombinationUnordered(
                randomCreatedMintCombinationIndex
            );
        }

        tokensAlreadyMinted.increment();
        return true;
    }
}

/*other contract implemenations - start*/
abstract contract ApeGeneratorImpl {
    function totalSupply() public view virtual returns (uint256);

    function removeMintCombinationUnordered(uint256 _indexToRemove)
        public
        virtual;

    function nrOfAvailableMintCombinations()
        public
        view
        virtual
        returns (uint8);

    function getSpecialApeIndex(uint8 _tokenId)
        public
        view
        virtual
        returns (uint8);

    function registerApe(
        uint8 _specialApeIndex,
        uint8 _randomNumber,
        uint8 _eyeColorIndexLeft,
        uint8 _eyeColorIndexRight,
        uint8 _tokenId,
        uint8 _apeNameIndex,
        uint8 _bananascore
    ) public virtual returns (bool);

    function endMintReduceTotalSupply(uint8) public virtual returns (uint8);

    function getTokenURI(uint8) public view virtual returns (string memory);
}

abstract contract accessControlImpl {
    function isAccessGranted(address _adressToBeChecked)
        public
        view
        virtual
        returns (bool);
}
/*other contract implemenations - end*/
