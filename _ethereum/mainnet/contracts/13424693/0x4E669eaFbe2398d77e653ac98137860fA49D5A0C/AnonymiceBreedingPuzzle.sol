// contracts/AnonymiceBreedingPuzzle.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./AnonymiceLibrary.sol";

contract AnonymiceBreedingPuzzle is ERC721Enumerable, Ownable {
    /*

  ____  ____    ___   ____   __ __  ___ ___  ____   __    ___      ____  __ __  _____  _____  _        ___ 
 /    ||    \  /   \ |    \ |  |  ||   |   ||    | /  ]  /  _]    |    \|  |  ||     ||     || |      /  _]
|  o  ||  _  ||     ||  _  ||  |  || _   _ | |  | /  /  /  [_     |  o  )  |  ||__/  ||__/  || |     /  [_ 
|     ||  |  ||  O  ||  |  ||  ~  ||  \_/  | |  |/  /  |    _]    |   _/|  |  ||   __||   __|| |___ |    _]
|  _  ||  |  ||     ||  |  ||___, ||   |   | |  /   \_ |   [_     |  |  |  :  ||  /  ||  /  ||     ||   [_ 
|  |  ||  |  ||     ||  |  ||     ||   |   | |  \     ||     |    |  |  |     ||     ||     ||     ||     |
|__|__||__|__| \___/ |__|__||____/ |___|___||____\____||_____|    |__|   \__,_||_____||_____||_____||_____|
                                                                                                           
*/

    using AnonymiceLibrary for uint256;
    string[] internal puzzlePieces;

    constructor() ERC721("AnonymiceBreedingPuzzle", "BABYMICEPUZZLE") {}

    function setPuzzlePieces(string[] memory _puzzlePieces) public onlyOwner {
        puzzlePieces = _puzzlePieces;
    }

    function puzzleForKeyPart2() public pure returns (string memory) {
        return "A35ef9B7B8";
    }

    function puzzleForKeyPart3() public pure returns (string memory) {
        return
            "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHgAAAATCAMAAABsiTl5AAAA81BMVEX///8EBwf8/Pzx8fH39/fV1dXDw8OvsLDh4uIMDw/19fXFxsacnZ3+/v7u7+/j5OSxsrKnqKifoKCWl5eHiIiQkZGKjIz5+fno6emqrKzb29u2t7eUlZX7+/v29vbr6+vm5ubd3d2Zmprt7e3f39/MzMy/wMC7vLy4ubm0tbWipKR+gIB7fX3Z2dnX19fQ0dF4enrNzs7Jysqsra2EhoZydHRnaWk1ODjs7e2kpqahoqKTlJSNj486PDwUFxe9vr5QUlJMTk5GSEgvMjLS0tLHyMhucHBjZGRbXV1WWFiAgoIcHh5CREReYGApLS0kJyciJCQ5Gw5uAAAD+klEQVRIx+1Ux27bQBScZVchxS5Soqjee7G6Lcm2YtlO+/+vCd9KCHzIIUgOueSBWGDwyJ23M8PF//rdEs4aoE9Hf7GDfX+Hknm/jAl07pcBpgPnmbecJzeN7lu2Qqj4+aIhE/U1UB0Za+GOpSwCudfHFgJ/r/JW5v7YRPP0WSGgnI4yps7gOuHbaich63kCgIAlX4sPLOUCKDyx1MQI0exxqneWMmcKrDOA9D1jbj5bLu1EminF2J3+nbFXak0YWwkHOd2VAVQujC3xibHLGsgfk/ckq4FaDoD6wFg1k0Fb+Ujs34gHCfF4/pFYbX4gRo2I8chYR39hqewHYqlNxMGXG/EX4ydxFduPxMlDUq9I6tVS4lKvXspoDmryTepFGmbfvkn9mkjt3aTOq2NAKCq4Sv35kEjtmwQSlS8y5MtpxqV+PCVSRzep+yuPpI4E/HmlSwBiCX9cema5hSC7W46Gi16Mwiff4KjzEupQlr00gecoW0du0q/z1i47kBGxB4WA6N4VIDqfprxV8OwGqtmdzEHNqaD8Nsnxluq3Smgv5zoAI8VSRcnFMAKgOXh2xNfEFwBofWUPHW3FWAigbtUzRbJ2QmNItgBf/3YNV+wydo9tspD9DVOczo2O3DATMnGujU2Q62vinWJRbiRGT4krCZct1GAQcc5GwQqS3V/4fO+Mqc9fGbMBjFppcS6skpbI3ZJGln5iqQUdOEnSU36fLBq92EXhMFIqPGrVgxGb6RNjR8pJEk0rd04xVqQE3bFHKW+7XoOMU/vRGFbqq4LrhpcAA/Y4JLRxJ1WE7+8znedpZ+mouw53a/z9IYvhE/8jAWXiK8i89VsEzMVkjM63FFEh7fv7GC/sKOFfVs6ZAUHtwEFgF4H1xhQ4GtWaSGJy5qhut2NIG/M6bRj1A7T3LhdD6tgiJOV6w6G8UUWIqlXmqlmmiFIYirw1dgoCqo5MosV9qadIC7HV40MEmaxoFVo1fveFRk8ZztcOCZ+PNOsAV1M2FK5STZD28JB3ibfb1t4w6+U8kWZX5UwPaqZJZIItd7uI5GaPwqXMpYlR8fILslUrIt79DNc2CVdlDlnlqW6j02zNkoX+pkwshUFYR8SH9wWjBhexT6dyYKjVYrk0ownlLhqtaWYttMfAUBFLZsPUkNUoXAZUrVtFoUvhGhR9TdqH9pnk3NqbtqA6PU5csHtZWcxu9mNCu3AxhhN6Sp7Q2fMkjFx+xtJsoXp4Hsx3INT1ayq6e88kZG99BdtN1InpXH6xn84P2gM+uzBKA6VqHVT5XAUQKjnwSjfoui1cWxiudaBaFn5xCRlktTHUr6hO7q5pAdAIdECrCBxIch4Q5H8Z6h/U2m9gd+ZVVAAAAABJRU5ErkJggg==";
    }

    function puzzleForKeyPart4() public pure returns (string memory) {
        return "ZTRhMjM1NWU2NA==";
    }

    function puzzleForKeyPart5() public pure returns (string memory) {
        return
            "data:image/png;base64,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";
    }

    function puzzleForKeyPart6() public pure returns (string memory) {
        return
            "data:image/gif;base64,R0lGODlhDQFHAIAAAFdXV////yH5BAAHAP8AIf8LWE1QIERhdGFYTVA8P3hwYWNrZXQgYmVnaW49J++7vycgaWQ9J1c1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCc/Pgo8eDp4bXBtZXRhIHhtbG5zOng9J2Fkb2JlOm5zOm1ldGEvJyB4OnhtcHRrPSdJbWFnZTo6RXhpZlRvb2wgMTIuMjknPgo8cmRmOlJERiB4bWxuczpyZGY9J2h0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMnPgoKIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PScnCiAgeG1sbnM6ZGM9J2h0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvJz4KICA8ZGM6ZGVzY3JpcHRpb24+CiAgIDxyZGY6QWx0PgogICAgPHJkZjpsaSB4bWw6bGFuZz0neC1kZWZhdWx0Jz5kZGUzMzY2OTwvcmRmOmxpPgogICA8L3JkZjpBbHQ+CiAgPC9kYzpkZXNjcmlwdGlvbj4KICA8ZGM6dGl0bGU+CiAgIDxyZGY6QWx0PgogICAgPHJkZjpsaSB4bWw6bGFuZz0neC1kZWZhdWx0Jz5kZGUzMzY2OTwvcmRmOmxpPgogICA8L3JkZjpBbHQ+CiAgPC9kYzp0aXRsZT4KIDwvcmRmOkRlc2NyaXB0aW9uPgo8L3JkZjpSREY+CjwveDp4bXBtZXRhPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAo8P3hwYWNrZXQgZW5kPSd3Jz8+Af/+/fz7+vn49/b19PPy8fDv7u3s6+rp6Ofm5eTj4uHg397d3Nva2djX1tXU09LR0M/OzczLysnIx8bFxMPCwcC/vr28u7q5uLe2tbSzsrGwr66trKuqqainpqWko6KhoJ+enZybmpmYl5aVlJOSkZCPjo2Mi4qJiIeGhYSDgoGAf359fHt6eXh3dnV0c3JxcG9ubWxramloZ2ZlZGNiYWBfXl1cW1pZWFdWVVRTUlFQT05NTEtKSUhHRkVEQ0JBQD8+PTw7Ojk4NzY1NDMyMTAvLi0sKyopKCcmJSQjIiEgHx4dHBsaGRgXFhUUExIREA8ODQwLCgkIBwYFBAMCAQAALAAAAAANAUcAAAL/jI+py+0Po5y02ouz3rz7D4biSJbmiabqyrbuC8fyTNf2jef6zvf+DwwKh8Si8YhMKpfMpvMJRQCm1Kq1Gs1qKdfudQsOL7zkqfgsLpPRbK3a244/3125fUn/3vfGvJUPOOSHFVjoM0hlqLiDaLb4aNMIAEk5I1mJ+XKJQWjgSDmZybB54RjqyXKKoyoKQWpxqsp6MltT2zramBErJdWZ6Pn7Kfw5RhiK/Kf3F/DV2RzLzFz4WjHd3IsKPawgjH1wm53NO4mMba79Lb5e/s1rWM016guMvm2abq/eIJ1/jtru3rt14HoFvIbLwy1ZBd2N0faO4T5+EAse/KduYEOJ/wAdpkuosNgzYAKD1TtWTlaxBNOwmHF2MtrKmMnumQSJM6fOnTx7+vwJNKjQoUSJrjTWrVQ4ea6IiJy1FF6EqBOrWoU1VdBHqpACOqAK9SEHrlwjicXplaIvejJZqSQ5lRg4l9GMoayX7+7RtSxZvjX1DI2+eX0JWuVYNhhEkvjchWtnD51Gf2oLs9vIB2FSyx87bw38ICJlx1c7Rq5oEjDczZw/00zsZDLrhphRb6UN7avkvP6WQqY82Lbvs7hlw2aiOtew1XBp0vOre7lzw2vvsk0tM3rbuU/bHi8KvcR38EbHkz+PPr369ezbu38PP4h5GHu/fpg/uyj+FsEJ7pqnLoFb6P23AlmtaTCfgOdJo1d2wjXIjzfaceddhNOVhCExBD7SmGh+cZMRa4/RZmB1JFY2V4jC4ZbbhotEdMxmHmYI2omeEecRhjjmyCBjhbmoSIe1eTTjOCyKI5tYu40m4opOEnnjTyN1R+F2Oq7WjXRgAZbbTdGlKN1zYr4EZHxmnolmmmquyWabbr4JZ5xyzklnnXbeGUABADs=";
    }

    function mintPieceForKeyPart7(uint8 _pieceNum) public {
        require(!_exists(_pieceNum), "Piece has already been minted!");
        require(
            _pieceNum >= 0 && _pieceNum <= 9,
            "Must enter a valid piece ID!"
        );

        _mint(msg.sender, _pieceNum);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token must exist");

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    string(
                        AnonymiceLibrary.encode(
                            abi.encodePacked(
                                '{"name": "Anonymice Breeding Puzzle Piece #',
                                _tokenId.toString(),
                                '","image": "',
                                puzzlePieces[_tokenId],
                                '",',
                                '"attributes":[{"trait_type": "Piece Number", "value": "',
                                _tokenId.toString(),
                                '"}]}'
                            )
                        )
                    )
                )
            );
    }
}
