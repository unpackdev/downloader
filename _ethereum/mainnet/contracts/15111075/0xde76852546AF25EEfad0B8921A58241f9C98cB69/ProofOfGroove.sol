//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./Strings.sol";

import "./base64.sol";

// import "./console.sol";

contract ProofOfGroove is Ownable, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    event StartSet(uint256 startBlock, uint256 setNumber);
    event FinalizeSet(uint256 setNumber);

    uint256 private _startBlock = MAX_INT;

    uint256 private _totalSets;
    uint256 private _groovesPerSet;
    uint256 private _price;
    // Community address that receives the _preSetMints when the set starts
    address private _communityWallet;
    // Team address that receives the _postSetMints when a set is finalized
    address private _teamWallet;
    // Address that receives the collected ETH. Will be a 0xSplit contract splitting 75% to the community wallet and 25% to the team wallet.
    address private _beneficiary;

    uint256 private _totalSupply = 0;
    uint256 private _preSetMints = 3;
    uint256 private _postSetMints = 5;
    uint256 private _currentSet = 0; // First set is 1. 0 => no started yet.
    string private __baseURI;

    mapping(uint256 => bytes32) private _tokenSeeds;

    constructor(
        uint256 totalSets_,
        uint256 groovesPerSet_,
        uint256 price_,
        address communityWallet_,
        address teamWallet_,
        address payable beneficiary_
    ) ERC721("Proof of Groove Generation Eternity", "PoG0") {
        __baseURI = "https://proofofgroove.com/api/0/";
        _groovesPerSet = groovesPerSet_;
        _totalSets = totalSets_;
        _price = price_;

        _communityWallet = communityWallet_;
        _teamWallet = teamWallet_;
        _beneficiary = beneficiary_;
    }

    function _mint(address to) private {
        uint256 tokenIndex = totalSupply();
        _tokenSeeds[tokenIndex] = keccak256(
            abi.encode(
                block.number + uint256(uint160(address(to)) + tokenIndex)
            )
        );
        _safeMint(to, totalSupply());
        _totalSupply = totalSupply() + 1;
    }

    function startSet(uint256 startBlock_) public onlyOwner {
        require(_totalSupply % _groovesPerSet == 0, "Set not finalized");
        require(_currentSet < _totalSets, "Last set");

        _startBlock = startBlock_;
        _currentSet = _currentSet.add(1);

        for (uint256 i = 0; i < _preSetMints; i++) {
            _mint(_communityWallet);
        }

        emit StartSet(_startBlock, _currentSet);
    }

    function finalizeSet() public {
        require(
            (_totalSupply.add(_postSetMints) % _groovesPerSet) == 0,
            "Not sold out"
        );

        for (uint256 i = 0; i < _postSetMints; i++) {
            _mint(_teamWallet); // TODO: To team wallet
        }

        emit FinalizeSet(_currentSet);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function mint(address to) public payable {
        require(block.number > _startBlock, "Sale not started");
        require(_currentSet > 0, "Set not started");

        require(
            totalSupply() < _currentSet.mul(_groovesPerSet).sub(_postSetMints),
            "Set sold out"
        );
        require(msg.value == _price, "Price not met");
        _mint(to);
    }

    function getTokenSeed(uint256 tokenId) public view returns (bytes32 seed) {
        return _tokenSeeds[tokenId];
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        payable(_beneficiary).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        __baseURI = baseURI_;
    }

    function getTraitBase(uint256 tokenId) public pure returns (string memory) {
        return
            ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][
                tokenId % 12
            ];
    }

    function getTraitInstrument(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        bytes32 seed = getTokenSeed(tokenId);
        return ["Drift", "Island", "Dirty", "Button"][uint8(seed[0]) % 4];
    }

    function getTraitChill(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        bytes32 seed = getTokenSeed(tokenId);
        return
            [
                "Lethargic",
                "Sluggish",
                "Chill",
                "Relaxed",
                "Neutral",
                "Tense",
                "Nervous",
                "Fidgety",
                "Hectic",
                "Stressfull"
            ][uint8(seed[1]) % 10];
    }

    function getTraitBPM(uint256 tokenId) public view returns (string memory) {
        bytes32 seed = getTokenSeed(tokenId);
        return Strings.toString(85 + (uint8(seed[2]) % 26));
    }

    function getTraitScale(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        bytes32 seed = getTokenSeed(tokenId);
        uint8 slice1 = uint8(seed[3]);
        uint8 slice2 = uint8(seed[4]);
        uint256 random = (slice1 * 256 + slice2) % 300;

        string[24] memory scales = [
            "Major",
            "Aeolian",
            "Melodic Minor",
            "Mixolydian",
            "Dorian",
            "Phrygian",
            "Lydian",
            "Melodic Minor Fifth Mode",
            "Melodic Minor Second Mode",
            "Spanish",
            "Harmonic Minor",
            "Dorian #4",
            "Harmonic Major",
            "Lydian Dominant",
            "Double Harmonic Major",
            "Neopolitan",
            "Oriental",
            "Lydian #9",
            "Mystery #1",
            "Hungarian Minor",
            "Augmented Heptatonic",
            "Lydian Minor",
            "Double Harmonic Lydian",
            "Hungarian Major"
        ];

        uint16[24] memory weights = [
            24,
            47,
            69,
            90,
            110,
            129,
            147,
            164,
            180,
            195,
            209,
            222,
            234,
            245,
            255,
            264,
            272,
            279,
            285,
            290,
            294,
            297,
            299,
            300
        ];

        for (uint256 i = 0; i < 24; i++) {
            //for loop example
            if (random < weights[i]) {
                return scales[i];
            }
        }

        // Should never happen
        return scales[0];
    }

    function getTraitSet(uint256 tokenId) public view returns (string memory) {
        return tokenId.div(_groovesPerSet).add(1).toString();
    }

    function getTraitSetName(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        uint256 setIndex = tokenId.div(_groovesPerSet);

        return
            [
                "Live",
                "Drop",
                "Step",
                "Core",
                "Tech",
                "Dance",
                "Beat",
                "Synth",
                "Wave",
                "Break",
                "Drone",
                "Noise"
            ][setIndex];
    }

    // Helper function to avoid "Stack too deep when compiling inline assembly"
    function traits(uint256 tokenId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{ "trait_type": "BPM", "value": "',
                    getTraitBPM(tokenId),
                    '"}, { "trait_type": "Scale", "value": "',
                    getTraitScale(tokenId),
                    '"}, { "trait_type": "Chill", "value": "',
                    getTraitChill(tokenId),
                    '"}, { "trait_type": "Instrument", "value": "',
                    getTraitInstrument(tokenId),
                    '"}, { "trait_type": "Set Name", "value": "',
                    getTraitSetName(tokenId),
                    '"}, { "trait_type": "Base", "value": "',
                    getTraitBase(tokenId),
                    '"}]'
                )
            );
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

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "Proof of Groove Generation Eternity #',
                            tokenId.toString(),
                            '", "description": "A uniquely generated piece of music with matching visual representation.",',
                            '"image": "',
                            _baseURI(),
                            "image/",
                            tokenId.toString(),
                            '.svg",'
                            '"animation_url": "',
                            _baseURI(),
                            "animation/",
                            tokenId.toString(),
                            '",'
                            '"external_url": "',
                            _baseURI(),
                            "jump/",
                            tokenId.toString(),
                            '",'
                            '"seed": "',
                            Strings.toHexString(uint256(getTokenSeed(tokenId))),
                            '",'
                            '"attributes":',
                            traits(tokenId),
                            "}"
                        )
                    )
                )
            );
    }
}
