// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./base64.sol";
import "./Strings.sol";
import "./ITokenSVG.sol";

contract TokenSVG is ITokenSVG {
  string public constant DESC =
    "For the PEOPLE of ConstitutionDAO who made history.Imagine there's no heaven,It's easy if you try,No hell below us,Above us,only sky.Imagine all the people,Living for today.Imagine there's no countries,It isn't hard to do,Nothing to kill or die for,And no religion too.Imagine All the people,Living life in peace...You may say I'm a dreamer,But I'm not the only one,I hope someday you'll join us.And the world will be as one,Imagine no possessions,I wonder if you can,No need for greed or hunger,A brotherhood of man.Imagine all the people,Sharing all the world...You may say I'm a dreamer,But I'm not the only one,I hope someday you'll join us,And the world will live as one.";

  function getCoordinatesStrings(int128 x, int128 y)
    public
    pure
    override
    returns (string memory sx, string memory sy)
  {
    string memory xPrefix = "";
    if (x > 0) {
      xPrefix = "E";
    }
    if (x < 0) {
      xPrefix = "W";
    }

    string memory xStr;
    if (x >= 0) {
      xStr = Strings.toString(uint256(int256(x)));
    } else {
      unchecked {
        xStr = Strings.toString(uint256(-int256(x)));
      }
    }

    string memory yPrefix = "";
    if (y > 0) {
      yPrefix = "N";
    }
    if (y < 0) {
      yPrefix = "S";
    }

    string memory yStr;
    if (y >= 0) {
      yStr = Strings.toString(uint256(int256(y)));
    } else {
      unchecked {
        yStr = Strings.toString(uint256(-int256(y)));
      }
    }

    sx = string(abi.encodePacked(xPrefix, xStr));
    sy = string(abi.encodePacked(yPrefix, yStr));
  }

  function tokenMeta(Meta memory meta)
    external
    pure
    override
    returns (string memory result)
  {
    (string memory sx, string memory sy) = getCoordinatesStrings(
      meta.x,
      meta.y
    );

    string[14] memory parts;
    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 360 360"><rect width="100%" height="100%" fill="#353535" /><foreignObject width="360" height="360" x="0" y="0"><body xmlns="http://www.w3.org/1999/xhtml"><style>.a{font-family:sans-serif;margin:10px;color:#fdf9f3;text-align:center;}.g{font-size:16px;font-weight:500;height:25px;margin-top:0px;}.b{font-size:12px;line-height:35px;margin-top:20px;}.c{margin:5px 0 auto auto;font-weight:800;font-size:0;height:45px;line-height:40px;}.c > span {vertical-align:middle;}.d{font-size:2rem;}.e{background-repeat: no-repeat;background-image: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB4AAAAoCAMAAADezbogAAAC/VBMVEUAAAD/sHbatIrGjGzmu4XKjlfuypfjtYTkuozMk3LpwY3Tll/qxZjovYbern7pv4jjtYHnvo+2ZzTgqnPMklzfs4nrw4/bq33owpXSnWzmtnnVoXLWnmm1ZTXVoG/EgEbPl2TvzZm3bEW6cETNmm3OmGiqTTbSpX69e03y2Ky6e2vouYjnu4Lcqne0a0K7cELrw5HMiFepUy3dsIPUnGa5ZTfnvIi6cUDAeUTVonK+d0Lfs4bEhU3OlGDTmmXkuYfFiVO5dFDgtorsxY/vzJvrwonQm2ypTzPw0qfCgEvtx5PrwYTLlGPBfUjrwYahMx3DhFXqv37QnW7iv5PDhF69dEzGhlTQpY7Bd2DwyIrkt4TOlF3AeEq/dkmfLRLEf1KvYTepPRrYqHrJjVfIjlnaqXntypa4bjrGiVTLkV7AfUnHiU/RmmnbrIC7dUbLiVLpvYWxWSraqoDUnWvToG+lQSOhPyfLk2KtUjXuzJzKkV7SoHPtx5LrxY3Yq4PUmW60ZELFiVTqw4ehNB/kw5+zYE3JmmuPGAjuypfvy5nuyZXuyJPvzJvux5DsxY/vzZ3sxpHtxY3ux5PsxIvuyZTtx5bsxpTswojqwIjrwYrmvIndsITbrIHnuX7lvJHjuY/rw47sxI3ov4vkuYjjtofrw5LqwpDmvY3luozesojfsYHZm2Lvy5jowI/sxIrpvYPhsHzrtXrZp3fYlVvvzp/pwpPit4vgs4frwYbqv4bkuIXgs4TvvIK/dj//2J391Zvnv5Phtormt4LcpnPYpHHdo23Pl2PUmGLNk2DPk1vBfEPw0KLzxI75yYfvvYfrwILbq33msHrZom7Tnmzcn2jQhVDDgErDfUjCcUC7cDm5aTm4YzO5azC0YSqvVirryJr80Zf1yJbwxIvfs4v1xYbpu37aqHnqsHjfqnfkq3TQmmfCbjS4SiCxNhX30J/7zo7twYzrvYnlsoLmsoDfsoDgr37ipm7lqmngo2XWk2PHhlXKi1LFh07Fhk3Lfk2uHjBdAAAAiHRSTlMAAQMF/v7+/vsK/v79/f38/PrF/v79+/v6xf7+/v78+8aOeVJLOTIqHxkQ/v7+/v38/Pz7+PHv6NXQ0MbBurmwsKqppqGXk46NgXVycnJsa2VgXEZDPjAbFv79/Pz8/Pv59vX18/Lv7+rg3dzZ1c/NzMK4t66toqGflZCOg4B3dnBqYkkqKCYgy38ewgAABE5JREFUOMt1k3OQHEEUxjvJ7t3llLvwYtu2bdu2bSfd06O17T3bdmzbtlXp2638mVfdNVXzvd97r743A8qB/0S5lpNHjACg2f6GQ4cOHjxkyM6Ge/aOHj1u4qGJ40aNath/Q7cH996AZvNex2bdy87OysrKPv329OlHjzJiH5y6/+7L8yrFl7+D8a8Xdoyo7kP7yKuHzvJrW6dLScerc+bOb99pQd3uAxuB8a8CYnijPcdgOFe76Ef7Gzfv3Ol0p+71G+3aXRtIJjj88vZVfVzcxRclVzJv3r5963rmlSslVYvitDXO7wMVwfGuxULhCRKZmVd/Cau+uFhQkB/82W1NdlkngwoAbIyvf+vW9d9Viy5qNenpvpa0vDapSpUuL6Ze8zK50cv6wqICjUHvSAyUG1UmViRiRKxKkLeoJSgPwDRhXLA18S7HYchxkGF4nqIRLat+qr/HsoprPvhG+tA0R1EIRkBKgSmO5uXVTw0iMMnY0tovUk4hDklpBDkYBTkaSYyCM70JS7oPOxNqM2LMQXzyJJQyIkhjilVWOb+JoKRA87W2DjoW0bQUJUCEGYqi5HJjyNOaRCanVc/3QbpUjkMQQoqDNKQQz/v71hlDUFK8aWGI2S6DERglcDRNIyyixCpBlZXTvcVbCGMiZTRENEpISEAUljJiNloXHD7AO3mrdRcEvA8FMck4CUUsjxlldHTI875lNLkT6tRSYhSBpaisLctikZhXCmJrAo8KenzTRbOQcGVDsxLyFKtSKxHZG+u/1npswjgCsxRmoxSKKJHksa5NbE/gxRvEVjKKGQkDWUmUJOXsWYWJja4leDoMVPDI/TIq8ViMWWIZg0VnU1JYSaou5NKUssnJ7ZsRpPRBUorYgkUmRZRCkpJa6XwDQv6jjcQwMc1gRqEQi0S8RCX4uPtYRW/vzRn+PEJICiOQmIEUSTGx/tZ6wuZeX2qe6SBHmGKkNEVzyCSRSEzGSKe7uCmRSTTI81dRUMxIIQMRjGJ5cXRQUFqN4iagAoHLr67SWiUjjlEIi2mTUimXmdVm3+DCSV65T3yIjeUpmUyuYmVKnc4/Uq22WDsXjiEyOU0WtzXb7DKZzWa3m4PMAkGiw2JJr3Fpl4eueHD7UrXZHGizJyaqBQ61Iycnx5nkquHZKPkcAgLy09LUgZFqhyXN4nTq9fqk3GRN7Z+9gKd2/hO31enQOy1W33R3usGQm+RyaeIKSpdPB+QvmxSj1SQbDIbk3ORgl0ar1WiqJentypmlmVMI3rL3s9pxWtfDh9pz2ifac+5cx10fTJaTUv9yIwCOLMuWqz+5Na5q1TpX8/MLDQ0LDAyz+MbEuOtd3gHAoPvdQsPC/Pz0SU7rs8Lw+PjwC/kXAkqFs6t2+bMNgD7kRfil8IDSkiUrVlUui149unete+PatZuvhgPQovHYkSPHTmg8dVqLGZ4NgvIVWs04OrXxgeFbm4G/oWYM72q5ssUAAAAASUVORK5CYII=");background-size:100% 100%;display:inline-block;font-size:1.2rem;line-height:40px;}.f{padding:0px 10px;display:inline-block;color:#a4752a;}.h{font-size:12px;margin:50px 0 0 50px;text-align:left;-webkit-transform-origin-x:0;-webkit-transform :scale(0.8,0.8);}ul{list-style-type:disc;margin:0 0 0 -20px;}.i{margin:5px;justify-content: center;display:grid;grid-template-columns:repeat(3,max-content);grid-template-row:repeat(3,auto);grid-column-gap:5px;justify-items:start;}</style><div class="a"><div class="b">PEOPLELAND</div><div class="c"><span class="d">(</span><span class="e"><span class="f">';

    parts[1] = sx;
    parts[
      2
    ] = '</span></span><span class="d">,</span><span class="e"><span class="f">';
    parts[3] = sy;
    parts[4] = '</span></span><span class="d">)</span></div><div class="g">';
    parts[5] = _getSlogan(meta.slogan);
    parts[6] = '</div><div class="h"><ul>';
    parts[7] = _getInviteString(meta.isPeople, meta.isBuidler, meta.invite);
    parts[8] = _getMintAndGiveToStr(meta.mintedAndInvitedList);
    parts[9] = '<li>Neighbors:</li></ul><div class="i">';
    parts[10] = _getNeighborsStr(meta.neighbors);
    parts[11] = "</div><ul><li>";
    parts[12] = _getEndTip(meta.mintedAndInvitedList.length);
    parts[13] = "</li></ul></div></div></body></foreignObject></svg>";

    string memory svgStr = string(
      abi.encodePacked(
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        parts[5],
        parts[6],
        parts[7],
        parts[8]
      )
    );

    svgStr = string(
      abi.encodePacked(
        svgStr,
        parts[9],
        parts[10],
        parts[11],
        parts[12],
        parts[13]
      )
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Land #',
            Strings.toString(meta.tokenId),
            '", "description": "',
            DESC,
            '", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svgStr)),
            '"}'
          )
        )
      )
    );
    result = string(abi.encodePacked("data:application/json;base64,", json));
  }

  function _getSlogan(string memory _slogan)
    private
    pure
    returns (string memory)
  {
    return
      bytes(_slogan).length > 0
        ? _slogan
        : "<br/>For the PEOPLE of<br/>ConstitutionDAO who made history";
  }

  function _getInviteString(
    bool isPeople,
    bool isBuilder,
    TokenInfo memory info
  ) private pure returns (string memory result) {
    if (isPeople) {
      result = "I'm this PEOPLE ^_^";
    } else if (isBuilder) {
      result = "I'm the BUILDER ^_^";
    } else {
      result = string(
        abi.encodePacked(
          "Thanks to ",
          _getTokenIdAndCoordinatesString(info.tokenId, info.x, info.y),
          " for the invite"
        )
      );
    }

    result = string(abi.encodePacked("<li>", result, "</li>"));
  }

  function _getMintAndGiveToStr(TokenInfo[] memory infos)
    private
    pure
    returns (string memory _str)
  {
    string memory _mintStr = "";
    string memory _giveToStr = "";
    if (infos.length != 0) {
      for (uint8 i = 0; i < infos.length; i++) {
        TokenInfo memory info = infos[i];
        if (info.hasTokenId) {
          _giveToStr = string(
            abi.encodePacked(
              _giveToStr,
              " ",
              _getTokenIdAndCoordinatesString(info.tokenId, info.x, info.y)
            )
          );
        } else {
          _mintStr = string(
            abi.encodePacked(
              _mintStr,
              " ",
              _getCoordinatesString(info.x, info.y)
            )
          );
        }
      }
      _str = string(
        abi.encodePacked(
          bytes(_mintStr).length == 0
            ? ""
            : string(abi.encodePacked("<li>Minted", _mintStr, "</li>")),
          bytes(_giveToStr).length == 0
            ? ""
            : string(abi.encodePacked("<li>Invited", _giveToStr, "</li>"))
        )
      );
    }
  }

  function _getNeighborsStr(string[] memory tokenIds)
    private
    pure
    returns (string memory _str)
  {
    string[8] memory _arr;
    for (uint8 i = 0; i < 8; i++) {
      _arr[i] = string(abi.encodePacked("<div>#", tokenIds[i], "</div>"));
    }
    _str = string(
      abi.encodePacked(
        _arr[0],
        _arr[1],
        _arr[2],
        _arr[3],
        "<div>Me</div>",
        _arr[4],
        _arr[5],
        _arr[6],
        _arr[7]
      )
    );
  }

  function _getEndTip(uint256 count) private pure returns (string memory) {
    if (count >= 2) {
      return "Imagine and build!";
    }
    return "I'm carefully selecting our neighbors!";
  }

  function _getTokenIdAndCoordinatesString(
    uint256 tokenId,
    int128 x,
    int128 y
  ) private pure returns (string memory _str) {
    _str = string(
      abi.encodePacked(
        "#",
        Strings.toString(tokenId),
        _getCoordinatesString(x, y)
      )
    );
  }

  function _getCoordinatesString(int128 x, int128 y)
    private
    pure
    returns (string memory _str)
  {
    (string memory sx, string memory sy) = getCoordinatesStrings(x, y);
    _str = string(abi.encodePacked("(", sx, ",", sy, ")"));
  }
}
