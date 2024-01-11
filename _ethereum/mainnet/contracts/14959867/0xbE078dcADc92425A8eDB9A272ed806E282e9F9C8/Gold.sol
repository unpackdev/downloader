    // SPDX-License-Identifier: GPL-3.0
    // solhint-disable-next-line
    pragma solidity ^0.8.12;

    import "./ERC721A.sol";
    import "./ReentrancyGuard.sol";
    import "./Ownable.sol";
    import "./Strings.sol";

    contract Gold is ERC721A, Ownable, ReentrancyGuard {
        struct SettingsStruct {
            string project;
            string name;
            string symbol;
            string baseURI;
            uint256 mintingPrice;
            uint256 mintingMax;
            uint256 maxSupply;
            uint256 totalMinted;
            uint256 totalBurned;
            uint256 totalSupply;
            uint256 gasMultiplier;
            bool comingSoon;
            bool open;
        }

        using Strings for uint256;
        // Public attributes for Manageable interface
        string private baseURI;
        bool private comingSoon;
        uint256 private gasMultiplier = 4;
        uint private maxSupply;
        uint256 private mintingMax;
        uint256 private mintingPrice;
        bool private open;
        string private project;
        address public secret;
        uint256 public signatureDurationTime = 3600;
        // Events 
        event withdrawEvent(address, uint256, bool); 

        // solhint-disable-next-line
        constructor() ERC721A("Gold Pass","W3BXGOLD") {
            project = "Web3 Expo NFT";
            mintingPrice = 1200;
            mintingMax = 5;
            maxSupply = 7450;
            open = false;
            comingSoon = true;
            secret = 0x96F9A58B5e5753c3477B645b72415Fd10eDb84Fa;
        }

        /**
        *  Minting function
        */
        function mint(bytes memory signature, uint256 price, uint256 tokenAmount, uint256 timestamp) public payable nonReentrant {
            require(open, "Contract closed");
            require(_verify(signature, price, tokenAmount, timestamp), "Invalid signature.");
            require(verifySignatureExpiration(timestamp), "Signature expired.");
            require(verifyTransactionAmount(price, tokenAmount), "Insufficient ETH.");
            require(verifyTokensAvailability(tokenAmount), "Supply limit.");
            require(verifyTransactionLimit(tokenAmount), "Too many tokens.");
            buy(msg.sender, tokenAmount);
        }

        /**
        *  Minting function by owner
        */
        function mintByOwner(address receiver, uint256 tokenAmount) public  nonReentrant onlyOwner {
            require(verifyTokensAvailability(tokenAmount), "Supply limit");
            buy(receiver, tokenAmount);
        }

        function buy(address to, uint256 quantity) internal {
            _safeMint(to, quantity);
        }

        /*
        * Owner can withdraw the contract's ETH to an external address
        */
        function withdrawETH(address _address, uint256 amount)
            public
            nonReentrant
            onlyOwner
        {
            require(_address != address(0), "200:ZERO_ADDRESS");
            require(amount <= address(this).balance, "Insufficient funds");
            (bool success, ) = _address.call{value: amount}("");
            emit withdrawEvent(_address, amount, success);
        }

        function verifyTransactionAmount(uint256 price, uint256 tokenAmount) internal view returns (bool) {
            return msg.value >= tokenAmount * price;
        }

        function verifyTokensAvailability(uint256 tokenAmount) internal view returns (bool) {
            return maxSupply >= tokenAmount + _totalMinted();
        }

        function verifyTransactionLimit(uint256 tokenAmount) internal view returns (bool) {
            return mintingMax >= tokenAmount;
        }

        function verifySignatureExpiration(uint256 timestamp) internal view returns (bool) {
            return block.timestamp < timestamp + signatureDurationTime;
        }
        
        function burn(uint256 id) external {
           _burn(id);
        }
        
        function setMintingPrice(uint256 _mintingPrice) external  {
            mintingPrice = _mintingPrice;
            open = false;
        }

        function setMintingMax(uint256 _mintingMax) external  {
            mintingMax = _mintingMax;
        }

        function setGasMultiplier(uint256 _gasMultiplier) external  {
            gasMultiplier = _gasMultiplier;
        }

        function setOpen(bool _open) external  {
            if (_open) {
            comingSoon = false;
            }
            open = _open;
        }

        function setBaseURI(string memory _baseURI) external  {
            baseURI = _baseURI;
        }

        function setSecret(address _secret) external onlyOwner {
            require(_secret != address(0), "200:ZERO_ADDRESS");
            secret = _secret;
        }

        function setSignatureDurationTime(uint256 _signatureDurationTime) external  {
            signatureDurationTime = _signatureDurationTime;
        }

        function _startTokenId() internal view virtual override returns (uint256) {
            return 1;
        }

        function tokenURI(uint256 tokenId)
            public
            view
            virtual
            override
            returns (string memory)
        {
            require(
                _exists(tokenId),
                "ERC721Metadata: URI query for nonexistent token"
            );

            string memory base = baseURI;

            // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
            return string(abi.encodePacked(base, tokenId.toString()));
        }

        function setMaxSupply(uint256 _maxSupply) external onlyOwner {
            require(_maxSupply >= _totalMinted(), "Total supply too low");
            maxSupply = _maxSupply;
        }

        function getSettings() public view returns (SettingsStruct memory) {
            SettingsStruct memory settings = SettingsStruct({
            project: project,
            name: name(),
            symbol: symbol(),
            baseURI: baseURI,
            mintingPrice: mintingPrice,
            mintingMax: mintingMax,
            maxSupply: maxSupply,
            totalMinted: _totalMinted(),
            totalBurned: _totalBurned(),
            totalSupply: totalSupply(),
            gasMultiplier: gasMultiplier,
            comingSoon: comingSoon,
            open: open
            });
            return settings;
        }

        function setMultiple(uint256 _maxSupply, uint256 _mintingPrice, uint256 _mintingMax) external  {
            require(_maxSupply > _totalMinted(), "Total supply too low");
            maxSupply = _maxSupply;
            mintingPrice = _mintingPrice;
            open = (mintingPrice == _mintingPrice);
            if (open) {
                comingSoon = false;
            }
            mintingMax = _mintingMax;
        }

        function _verify(
                bytes memory signature,
                uint256 price,
                uint256 tokenAmount,
                uint256 timestamp
            ) internal view returns (bool) 
        {
            bytes32 freshHash = keccak256(
                abi.encode(msg.sender, price, tokenAmount, timestamp)
            );
            bytes32 candidateHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
            );
            return _verifyHashSignature(candidateHash, signature);
        }

        function _verifyHashSignature(bytes32 hash, bytes memory signature)
            internal
            view
            returns (bool)
        {
            bytes32 r;
            bytes32 s;
            uint8 v;

            if (signature.length != 65) {
                return false;
            }

            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
                v := byte(0, mload(add(signature, 96)))
            }

            if (v < 27) {
                v += 27;
            }

            address signer = address(0);
            // If the version is correct, gather info
            if (v == 27 || v == 28) {
                // solium-disable-next-line arg-overflow
                signer = ecrecover(hash, v, r, s);
            }
            return secret == signer;
        }
    }