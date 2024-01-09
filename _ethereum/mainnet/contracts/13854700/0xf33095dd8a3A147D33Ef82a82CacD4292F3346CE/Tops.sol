//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";
import "./ITrait.sol";

contract Tops is Trait {
  // Skin view
  string private constant STRAPPY_TOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAMCI8BEk2B0FaMWNpOXR5QYaFvGz8AAAAAXRSTlMAQObYZgAAAHBJREFUSMft07sNgDAMRVE3GSArsILNBCZ9JPD+q5CPEEEYCoQUhHyKV93GhQGMUTmA2CcgYs67BafsvUBEopPqEPgk79RQb0AkJsbiItipgciMONZVA99Qg6GhBiEsSSieBcZ8DzNR/vKewc1f/t8KRdUnFMn/8bQAAAAASUVORK5CYII=";
  string private constant CHEF =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAAAyMzHNFB3gISLM2drh5unk5uPp7vCYXFw/AAAAAXRSTlMAQObYZgAAARtJREFUSMftlMFOwzAQRK1+BL2DENeqOfSMFJQfwPGdxtlzobvz+x0HWhHXSYS4ZuSDFb+dWSftOrdqVVHHqqque0EJcG5z3aMvAB/OPd0crOSw29wicB8BxP0eGr6qAwxphXFMwPHx86BoBMJTKoxdPOILnqE8iQkxrsyBz5VlLJcUYZlD0HjCNjnYeWCkzSI0CiuVPZyNEb0Ey3roWKbaqCk3bVpZD90JD7ynQRnR0iQD9Nsh0MP/KHOwhlccgLp+q5PGPXh7Nd7CEyh+bPXWGbxX9WH96a/6g2ALQI8FQJYcgIXj9L/sdQ5IyDQgaTZApmOGAWMzDqwmgzgN9AITmWmS04MZceY1cc6wjUmgOBt+i2Ph/W42/EsXOlyFE/2FZvkAAAAASUVORK5CYII=";
  string private constant PREHISTORIC =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVwcABjSBOEYBvhnhXspBT2yXBrTUdUAAAAAXRSTlMAQObYZgAAALxJREFUSMftlD0OwyAMRllygCRcgIQeINg9AP7MXqnh/lcpSdQlJUuXqhJv4cfPlkAYYxqNK7rfCJ6cGtPHQ1DNZ0Gn3hsz0L5YBelxEkiGe4nwNs+OP0soccnJ6xZfQ/Q2nYyc942ujM8ZAqwpVw+gCLcwkvKkWhUWgiMmliHOVSGqJwTAWa5XgAw0OrGCUK9A0SoketDiq0IPFIWhXlEXSMUCXJD27ht/gpb2PLr8gvTu8iv2nyO3m/ySF7D/I9Xi8JzlAAAAAElFTkSuQmCC";
  string private constant TSHIRT_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAA2NjY4ODg5OTnWDzk4AAAAAXRSTlMAQObYZgAAALtJREFUOMtjYBgFmMCBEURGIgQOMIPI+egCdegC/+H8cAemUAfm0OX/66ECsVdE/9aGl8dfvw8V+JkaW/8/vzb2fzpU4P/Sq5W19+un1ZdDBepD42P/ViK5qzb07v2v/5EE/t8trf9fiiRQHhpa/f4vkkD89PDculokgfehqdVf/yEJ3A+9ej/3O7It0+K/lt8cTQX4wVV0gSh0gW3oAt/Q+KGh67+jCJRfrf6JqiIs/z+KQOy6+q+DKRQA8fVFNXs3A+0AAAAASUVORK5CYII=";
  string private constant TSHIRT_WHITE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAB9klEQVR42u2a3W7DIAyFnUFFpb3/o04C1YjdzJHrQNM2JKPt+W76k8TKsU8MghABAAAAAAAAAAAAbCTGWJ459kj8GGO5XC6lR7zulFLKM8fuRYQLW+N9vZrDcs4UQiAiImamj3NAMWyN53s+8yEESik1z2Xmah84n89TS6yNJ1UXJ9gkpJRmhxARTdM07ZoAKz6EMIt0zn3nnImIfqx95Wa1M1rJ07HlnFqcEMLVufcw9bI8M9OfWHLOzd9r7rh1cyklcs6R935RUZ2gllC5XpK95oBuTdB7TyEEcs4thNeqy8yUUrr6XwTZ5OlYEl+E1lwjyTvEATHGUrNj7eatXW0F9TFxVKs/9KLrMFgTbwXq3y3x2lF7060H1DqxrXZN+Nq1wztAbrT12XKGnsTo75KcI6rf7RHQ1tZN0IrQMzjv/dwEpWlJYzySLo+ACGpV2w6L0uR0t64NkcxMp9Np/CbYGrZEkBWvq55SImaujuePDGf/5gA9DOpJiK18TWBrUqPj7N0EAQAAAAAAAAAA8HkMt9hg9wP3XhDxoyVAxNsdpr0Y7v0A59zN7bG3T8ARC6FD9YC193zkUbCJkUXUtd3fl3CA3g2yq8c5Z/LeL16Hae0Mv5UDZGlcvy+wELDRAcOMArI3oC0vVa+JP3oLDQAAAADvxy8j65Qi++Br+AAAAABJRU5ErkJggg==";
  string private constant TSHIRT_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAB/0lEQVR42u2awW7CMAyGG5qq6t6Syw6cdtszcJjEade9JVHVoOyA/s6YBBiEKMD/XaC0smL7txPVNA0hhBBCCCGEEELIjSzX23DNvf/YX6634f3LhRz2FrkDMPTmqnuX0tm9Ddvmsbd4NIVNPsyO+13zegGQWbft7fZszpofetO4MV2WfhfvAz+fb1EtrzYuaHvIOpSw2riDB9wYDoL0/TGYuwZAOz/0ZnYSjuFayheLhaPy+pRtPBOzM/Tm4NkiCtD16MbQdNY0kw9RdcjF6UXimc6aI3nH1AVbOhidvTwI2XoAujK6tA5QTMoIiHZo8mklwL50NLaWYj1AR1ovXktWqmDyxyrAPb/b20r1h1xk3QVi2dDylNepOs65z989ANohXd+6eaVqUzYwqZTqAyAXHPtMKUMeYuT3VIOsugRkVmUTjHV5OGzbvyyjaaExliTLNigzKJsgnMG2iGvb7p091QN0MKtWQGrbgkPyPuocWXdjOAoGfs9x1C26DcpDEDIYy6w+1KActJ3S5UAIIYQQQgghhJDXwNS2ID0PvPdcwNYWAPkesQTVjcc7a06Ox54+ACVehFbVA879z0f+JUaXytCbs/P/h1CAnAbp1+OTD/McQQcmx1vjKppgbJwGJycf5kmSLhXbmucIALKPeQAcRNZjfYEzA0IIIYTcyi9gyVB9JbpWGAAAAABJRU5ErkJggg==";
  string private constant VERTICAL_RED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVlLXTaT1Dg4t/t7+v6/PkXGOinAAAAAXRSTlMAQObYZgAAAIVJREFUSMft01EKhDAMBNAIHmAhcwGPMDfYQO5/Jq1UwSXdiPpn56vQR5IWItLTE+YrMmxnYwJoWYULACjA7CMyutPcgR9gaxSAu7UBoC3ACkqFqIWu9ywg/Ka9hSZA0wrLlA0wZeDEkKzPDIHWFs0he3rihJt9AEwA7V6LcLOfBvwPXpoZT/Eo1b+hauMAAAAASUVORK5CYII=";
  string private constant VERTICAL_GREEN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVlLXQ4xmPg4t/t7+v6/Pk83kfxAAAAAXRSTlMAQObYZgAAAIVJREFUSMft01EKhDAMBNAIHmAhcwGPMDfYQO5/Jq1UwSXdiPpn56vQR5IWItLTE+YrMmxnYwJoWYULACjA7CMyutPcgR9gaxSAu7UBoC3ACkqFqIWu9ywg/Ka9hSZA0wrLlA0wZeDEkKzPDIHWFs0he3rihJt9AEwA7V6LcLOfBvwPXpoZT/Eo1b+hauMAAAAASUVORK5CYII=";
  string private constant VERTICAL_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVldC3slA3/oxjg4t/5+/gVaV5HAAAAAXRSTlMAQObYZgAAAJhJREFUSMftlLENwzAMBOkgA7jgCD9BJsgT2n8mU7YDJBYpw3AZXSVAh3+qoEQGg5C3yONzNrstMBamjgDUBLNZ5FmKsRTgV1CrEArEAlbBAOguaCvQEzzCBUsTVA8XbYUmgm4VHtBNYB0yEV5bRTqD7kN2K1gTsiG9gk76zMEgJlz9b3gmhH/DhYpwcQ8CTwRa8zdcqvhTFu2fLhJzL3fyAAAAAElFTkSuQmCC";
  string private constant TURTLENECK_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAA9PT1CQkJGRkYh3l+BAAAAAXRSTlMAQObYZgAAAM1JREFUOMvt0rEKwjAQBmBn3+8KFepocbCbPbTgW6gEqbp0ucGxIMHHENGSjhWHdlTcbIe0zQniA/QfDvJxl5CQXq/Ld4iqWjSw71dVclB8BOs1KAWOOgqaaBACbPFekafhheAV17CBciSQqgXow7DqcOuOBFy5aQF6YOd4In0wOZJGiFuaa/BzUrs4pVhDKmntWgCWBllQdDBuT7SMul/wO4oDckg5BPybDaY3E8JZYoJjnxkUdxMW2cOEOBubgE8Oiu3h5xcDoMx/r/ABd61lED+9l94AAAAASUVORK5CYII=";
  string private constant TURTLENECK_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVhYmz2jCD3mTn4plAa+3z3AAAAAXRSTlMAQObYZgAAAM1JREFUOMvt0rEKwjAQBmBn3+8KFepocbCbPbTgW6gEqbp0ucGxIMHHENGSjhWHdlTcbIe0zQniA/QfDvJxl5CQXq/Ld4iqWjSw71dVclB8BOs1KAWOOgqaaBACbPFekafhheAV17CBciSQqgXow7DqcOuOBFy5aQF6YOd4In0wOZJGiFuaa/BzUrs4pVhDKmntWgCWBllQdDBuT7SMul/wO4oDckg5BPybDaY3E8JZYoJjnxkUdxMW2cOEOBubgE8Oiu3h5xcDoMx/r/ABd61lED+9l94AAAAASUVORK5CYII=";
  string private constant STRIPE_RED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVoAADoSC76UDLg4t/t7+z3+fb+//xTrp1TAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlE1uAyEMhVHVdF0sZV8/tRwgUi8QDbPujMD7VsH3P0IcVbMgYYq6562M/OGH+XNuaKipN+detjjHBvDq3GGLo3YqyHcH0OUhzTDgWdKXc085TwsQahsQv+cVHMrKYgNm1ECOSS0PaFJi8gymCog63fJGHBXBaBWuAElEUJmV8NHcJoBQNIkmUBNgOlpRM74vvSmJ/ICI4fXSBEo8ASLWJNqAzSarMmvmtgUz5dma5KK+vQb9TOzZUyhxXP2hf6isHSCfO8C8dAD920J1JbvbYReAZe1vwC5gX4O94J238WsxXQzI47hrXQGiRjKpvbWUKAAAAABJRU5ErkJggg==";
  string private constant STRIPE_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVvcm0neeErhfXg4t/t7+z3+fb+//z67CVSAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlE1uAyEMhVHVdF0sZV8/tRwgUi8QDbPujMD7VsH3P0IcVbMgYYq6562M/OGH+XNuaKipN+detjjHBvDq3GGLo3YqyHcH0OUhzTDgWdKXc085TwsQahsQv+cVHMrKYgNm1ECOSS0PaFJi8gymCog63fJGHBXBaBWuAElEUJmV8NHcJoBQNIkmUBNgOlpRM74vvSmJ/ICI4fXSBEo8ASLWJNqAzSarMmvmtgUz5dma5KK+vQb9TOzZUyhxXP2hf6isHSCfO8C8dAD920J1JbvbYReAZe1vwC5gX4O94J238WsxXQzI47hrXQGiRjKpvbWUKAAAAABJRU5ErkJggg==";
  string private constant STRIPE_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEX7AwDrkw3/oxjg4t/t7+z3+fb+//zA9QaHAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlE1uAyEMhVHVdF0sZV8/tRwgUi8QDbPujMD7VsH3P0IcVbMgYYq6562M/OGH+XNuaKipN+detjjHBvDq3GGLo3YqyHcH0OUhzTDgWdKXc085TwsQahsQv+cVHMrKYgNm1ECOSS0PaFJi8gymCog63fJGHBXBaBWuAElEUJmV8NHcJoBQNIkmUBNgOlpRM74vvSmJ/ICI4fXSBEo8ASLWJNqAzSarMmvmtgUz5dma5KK+vQb9TOzZUyhxXP2hf6isHSCfO8C8dAD920J1JbvbYReAZe1vwC5gX4O94J238WsxXQzI47hrXQGiRjKpvbWUKAAAAABJRU5ErkJggg==";
  string private constant SUIT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVjb2wKFh8PHiyQBQAZKDb09/M4xg+kAAAAAXRSTlMAQObYZgAAAPhJREFUSMftlEtuwzAMRJ1F9pWiHIADXiCLHsAED9Cg8P2v0pFiI0jNSItsPStJfCL1nWk6dChUWpa0tYEAuE7TfWurDYA8BJ4lAHy1EVx/zncgURB2sZZhf60qv99ZDTWE7Gy9ltkAZSgzyJaEANwl1/AesMtN62yXYooAcLlxODMDgymZzv8AFVG34io6hxnabMvKDN7WMO8BI1B3gdy2uwNSnefFllVBhscphJfNo0ECAXkDHDoUK/SG18c3AmRU4h1w4k+Q6hd0h7hMs4r6R+sL7yyR/7L39B/O0AVYYO4B1Rms9DMUG6zBexloggLp3EfoDR/pD84DPQp5evZaAAAAAElFTkSuQmCC";
  string private constant LUMBER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAABgMhCSLidiQSi6OjFkY2LRVk37zFfc3Nzp6elLjlLzAAAAAXRSTlMAQObYZgAAANtJREFUSMftlL8KwjAQh6O+QGulu5gHsFZ0tVc87C7uxRPs7BuIS1fp0LytsVLon2tFEEHIl+WGH98dJBchDAaWuRCDsgbgA6OyJmICViXAGqxKC8aAuBQiJnKFCBGJUFMLSLnYDEOApZQzKQGkpmlIsiPRCjHoMIyj68sw7TbEhaFzht01AJj0zXDTM7g9huj+xnDOXoZApfoolbYNYWGYsneJuE+yE9EBccsGbM9ZXxzftn3PNk/f8AHsZldh/4ZvGkgD0NiqegNmq5qG1l7+neH5L+QqVz+8/AfiPlMwOCAUmQAAAABJRU5ErkJggg==";
  string private constant COWBOY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAkFwY4JwqOHQqmIwhvNxEMVWqJQBIVWm8TZnr+1QAbz5SLAAAAAXRSTlMAQObYZgAAASxJREFUSMftlLFOwzAQhiPxBFnZyMiE1DwAUirlAaqLKx4gcvcepiui7t2K1HC38qSYFqrGdRMxsOXLkEj+8vu3EjvLJiaSwMNN+fusnBAWWXYSyCaE9ZnAqQR4nJ0Eq5fD+FLNSgCsSiBhLxr1MG7zVs0RzaJGq2JJhXqCQyfz0jlTrx1zx8ocJ+DzR20w3JGsshCvooSn5hUNgnNOrJKI7wvGmOUuvB8uFBIVFo5Wgc37QUD0ItwGog6u2YX47xLCFIgT3CEBggjtDz1BAZotgO7BbJLfsiiK+8/iSFLI8/z2Lj8y/foTf0B0RPA0liAjgvrhYQ57jgZ6KOlKPfHAGsLWl4EexGI9ddeFUIE8d/b6FOyZ4rPhnLb1zDba2b0ORJenSz8hcTb8L1/HE4qVeT7A/AAAAABJRU5ErkJggg==";
  string private constant HIGHVIS_JACKET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAACcnpv7mQD/pAW8vrvCxMHy+gD4/wDT7TsBAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlEGOwjAMRVmVda+AJQ5gS+UCcXsBe9ii6TTdIqDN9XE1KhLUpRfIX0Xy0/d3oni3y8pyhdc9zGdlFyhoPktwALgWh5eDeA6X4tVCdFEmoMueTPeKmIVFFzngcbYWdD9h4BAM+myDXQ0TcCTlidCwcGjQgNuJVIWVP3JY9+EMRNBW6F5Tin1XpzHG2EcXKMvyUZf/coHYp64ZYz+OKbkAIVlIuw2bwn8qwr/aQtJvBb4DwPCDeMB2xQEIhsampHbFISvLl/Nx3xV4A+AtB+WNsu0G+ZJDJASx7bAOWF00fHGYdoMq5+d+1xN/Fj0+ISur7wAAAABJRU5ErkJggg==";
  string private constant POLICE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAGGzMKJkICKUsGLE0eKDMqNUCwsq72yzL23DTj5eFBYsbWAAAAAXRSTlMAQObYZgAAARdJREFUSMftlEFOwzAQRXMF21CJpf9E2XsGWcCONFdI92mEe4NegCNwArY5JTYqC6dxEELd5S0sS3n+HjmjqaqNjUWaqjr+7EVuLtC1IOKn6fi9jiJCCrMUJv/yOQo8y5Fpj87CZgJx48zI7Ec/gFrgVbs8Ad49xLOnEM5we9teC8MuRCFEWGB1NxdoUKfA9q3vDyw1687kRWoa7vuDuJSg6dHWrUEmhDDs4v0hJRiq27qV/AqN9Ak2JRgnCkqpvAYOIdbASZsuzGpoQhgBH9fFn60uxGeWrfU3/sCvDXNzAYp4tXF1B3764LJwB6bnd3ZloTYcKQtx9BBjVdDMAIpCmgtC4BVBQyCqKMTBEF/BmqKwOBv+xRclPU913ozfnwAAAABJRU5ErkJggg==";
  string private constant DOCTOR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAABNTU0SYKEVbriournH2dnW4+Pp6enu7u7y8vL09PQCAr0yAAAAAXRSTlMAQObYZgAAAU9JREFUSMftlEFugzAQRVkmNylHYJ9F0n2P0DtkmaqVYrxqQxb+cwLPP2W/Q1OVyDSq1CUfBAae/e0xM02zaFFV583Grm2yAmya9eO17VYBds16d20DdwD692sjDuphwO59vTXwIvNyHQGwABQwdFvCSD3QaDbawHLBHHg7tU/6ap70dNaL0SbbXtfgJqB7Vj+1NNxZt3El4SiHZhXgL0ObyJ7IDv9wYZM1mOWhfaH39ER3K8cUYD51UYAjEa654AZAGrro7CELo5Zp03CbyyK6RTAH9CGFkCcAmU5tNGiE1OurFG+AMgdZOHJ1s+F4fVCIo8jl11/0B1Vrw09Va8Pk58MdwOYsVlDKYVIbboBLxrmSSnnrtSGiqziMp1XncfRopVBAXlVgtQ/hULJaB3+JgpuSez4WWofNWXwFuvSnzwJBpQEhhnlA6lMO/7f5n/dF3uKgDgDjAAAAAElFTkSuQmCC";
  string private constant SCARF =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWcTXHw0fqUlkclQ/2RTAAAAAXRSTlMAQObYZgAAAD5JREFUOMtjYBgFmOBdHJpAAzOagAO6wKtqVP6y37d2vZuHJBCWuT1yWxiKGml0e9nQBbjRBVhGI2cUDCIAAPcdC0Sriwc2AAAAAElFTkSuQmCC";

  // Front view
  string private constant FRONT_STRAPPY_TOP =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAB5QYZpOXRaMWM8BEk2B0FPX/j/AAAAAXRSTlMAQObYZgAAAEFJREFUGNNjYKAaYGRgEMDBEBRgFAQzlIAAzDBSNlIGM4yBAMwQNjY2BDNcgADMCAUCMEMICFAZykBAiAE3hxIAAIn5CUPRP/A/AAAAAElFTkSuQmCC";
  string private constant FRONT_CHEF =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAADp7vDk5uPh5ungISLNFB0yMzHM2dqz5iDyAAAAAXRSTlMAQObYZgAAAGRJREFUGNO9jTEKwzAQBO8LcybuFxnUS0VqF35ACH6A/ANjiL6fU94QvM3CDOya/Sl42jaQwbI/VjAnvXg7Q6FJbijNNGkoCYUqOWqokmeOILUOUqtd3U/oz9j2j7ffieeYuzVfCIcMvEFIXXoAAAAASUVORK5CYII=";
  string private constant FRONT_PREHISTORIC =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAD2yXDspBSEYBtjSBPhnhV+54yIAAAAAXRSTlMAQObYZgAAAFlJREFUGNNjYKAmYIQxhKC0oAmUFgqG0KKmqmBGsGGwK5ihahIaBGYYhapC1DiHukJ0OSmpKkPUqDgpgRlKyk4Q7SZKSoJghouRogBEVyCEZggSgNlNDR8BADOYCcf2m7C4AAAAAElFTkSuQmCC";
  string private constant FRONT_TSHIRT_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAABfSURBVCjP3czBCcNAEEPRt5rUtLj/S8A9zZLD2iYlhOgi9IXEb2gcVvUJjoUxFe00qd6gZdlREp2gtKQMmKC8kfu9aDcopas9oPXVXyDUXl1g0fL1AbW2vyBLei/+Sh92QxnEYz6W1wAAAABJRU5ErkJggg==";
  string private constant FRONT_TSHIRT_WHITE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAQAAACxgDBHAAAAgElEQVQ4y+3Q2wrDIBCE4c8asND3f9RCJBV7kcOakgfoRRZEdMad3+UuSEunKapniuult90wdwqoyK/GG4o6Giqy/dUukqW1WQZtEDMmH0fu3IOgIG3K45c6eH4MZVt1IMB1BI5PHx3yEBD7YGgxi2uGYGmn8xQR6zzqKeCuf6ovmrclCB/qexQAAAAASUVORK5CYII=";
  string private constant FRONT_TSHIRT_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAABmjfdhifZqkPe4/L/QAAAAAXRSTlMAQObYZgAAAEBJREFUCNdjYCASRDcwrmJY/0LrFcO6WetWMmRGvYplYFi1Hiiz6h2QeLcLxFoFJLJXg1izQMQrIJG5nlgbsAIAPkMTzjoNkgwAAAAASUVORK5CYII=";
  string private constant FRONT_VERTICAL_RED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAADt7+vaT1D6/Png4t+h3+a4AAAAAXRSTlMAQObYZgAAAC5JREFUGNNjYKASEDIyYGBgMjJiMIICBEPISAhICRkBVYH5DPgZTlikhNCk6AYAf9ELa7EDmbwAAAAASUVORK5CYII=";
  string private constant FRONT_VERTICAL_GREEN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAADt7+s4xmP6/Png4t9g4G7rAAAAAXRSTlMAQObYZgAAAC5JREFUGNNjYKASEDIyYGBgMjJiMIICBEPISAhICRkBVYH5DPgZTlikhNCk6AYAf9ELa7EDmbwAAAAASUVORK5CYII=";
  string private constant FRONT_VERTICAL_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAD5+/j/oxjslA3g4t9iQy2/AAAAAXRSTlMAQObYZgAAADZJREFUGNNjYKASEBIWYGBgEhICMoRAQBjKEAaKQGghkCohMIXKEEYVccKtxklIWJhaDiYOAAAMrAS1M4ONyAAAAABJRU5ErkJggg==";
  string private constant FRONT_TURTLENECK_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAABpSURBVCjPzdCxDQNBCETRdwiCbesKd1sbQOBgT67Akj0/+iMmgf/IdXf12gdK0DUOJTtYnasPCPCZPMXjZamAx7NsYT0XldNk2MrxhMizqZzcmNh2r71MzrL1BXdOmpwXEoxhfv3Gr+cNlQs5SgvhgjUAAAAASUVORK5CYII=";
  string private constant FRONT_TURTLENECK_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD3mTn2jCD4plD1RLbEAAAAAXRSTlMAQObYZgAAAElJREFUCNdjYCASpL17t5QhMy0tjyHv9+51DHnv3gGJ3Tv3AlnPKxnqds/dzZC7rnw3w9ud93YyrHpbvoqBofwuUF9oKLE2YAUASgUcgbsGDRoAAAAASUVORK5CYII=";
  string private constant FRONT_STRIPE_RED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAADt7+z3+fboSC76UDL+//zg4t8rmtWlAAAAAXRSTlMAQObYZgAAAFxJREFUGNNjYKASEFR2YGBgVDFhMHF2dlRScXFmMDFWDFVxMVZkEFIUBPIFA4GqTExcQsHKTVyCIAyjUFVnMEM1xMUEzEhxcVGFqDFRhDKURCFqkhSdjanlYOIAAHH5DOZvM6uHAAAAAElFTkSuQmCC";
  string private constant FRONT_STRIPE_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAADt7+z3+fYneeErhfX+//zg4t8twd8zAAAAAXRSTlMAQObYZgAAAFxJREFUGNNjYKASEFR2YGBgVDFhMHF2dlRScXFmMDFWDFVxMVZkEFIUBPIFA4GqTExcQsHKTVyCIAyjUFVnMEM1xMUEzEhxcVGFqDFRhDKURCFqkhSdjanlYOIAAHH5DOZvM6uHAAAAAElFTkSuQmCC";
  string private constant FRONT_STRIPE_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAADt7+z3+fbrkw3/oxj+//zg4t+EruBNAAAAAXRSTlMAQObYZgAAAFxJREFUGNNjYKASEFR2YGBgVDFhMHF2dlRScXFmMDFWDFVxMVZkEFIUBPIFA4GqTExcQsHKTVyCIAyjUFVnMEM1xMUEzEhxcVGFqDFRhDKURCFqkhSdjanlYOIAAHH5DOZvM6uHAAAAAElFTkSuQmCC";
  string private constant FRONT_SUIT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAAKFh8PHiz09/MZKDaQBQC6OIC8AAAAAXRSTlMAQObYZgAAAGBJREFUGNO1jYEJgDAMBCMuYCoOkOcHUIoLhC5Q3H8Xk3YFfcJzHCER+SgF+7leMCnN7idK4AmEcIIL4UePEmqzDk1Ds2GcXlrslASnSa109VrjdprxhFAMwLZM0DH/5QXVxg9lyNDWVAAAAABJRU5ErkJggg==";
  string private constant FRONT_LUMBER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAADRVk26OjFiQShgMhCSLifp6enc3NxkY2L7zFc4dVrNAAAAAXRSTlMAQObYZgAAAFVJREFUGNNjYKASEBIyYmAQERJiUFU1VWBVVlUFiYglCYNFXNVK4SJQNeqlKlCRIogaU7VUkEhamZF4knBaGdBIoIgy2OwmsSQJMMPZcrIztRxMHAAAU3sPFfsn/DYAAAAASUVORK5CYII=";
  string private constant FRONT_COWBOY =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAIVBMVEUAAAAVWm8TZnoMVWqJQBKmIwiOHQpvNxH+1QA4JwokFwZY6uHRAAAAAXRSTlMAQObYZgAAAG9JREFUGNNjYKASEBJ2DEtLFVJkUDR0Eg0LVTJiUBZyUQxNVRJiUBJyd1YJUTRkUBKsKJZ0VxRkUFQqKRRxFxZiUBRyL9YEMQQFXYpFXASVGIyNQSLGxkAjy4vFy8Fmz5zRORPMWLVi1ipqOZg4AAAIXRUILf2sbAAAAABJRU5ErkJggg==";
  string private constant FRONT_HIGHVIS_JACKET =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAADCxMG8vrv/pAXy+gD4/wD7mQCcnpvRgHh+AAAAAXRSTlMAQObYZgAAAF1JREFUGNNjYKASEFI0dmA1FlJkUFJKDhJNU1JiUFQyc1RJVhICSiUHqZoBpRgYjANFk8HKXR1VQsGM8iCVcjAj1FE1BMwwBioGM8ycVCCKkwNFzKAMVWNqOZg4AAAc8g4MOkwg4gAAAABJRU5ErkJggg==";
  string private constant FRONT_POLICE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAAACKUsKJkIqNUDj5eEGLE0GGzP23DSwsq4eKDN1tAz/AAAAAXRSTlMAQObYZgAAAHFJREFUGNOtzjEOwyAQBMD9AofjnkOmh5OQ3Z/c4x9gS0R5jyt+G5QXpPCUW+wu8BDjrGpyhMJ22iMTDvZzjeRQgp3fqRI45EsSOyyU2yon4RXyp9+VsRz5GgnDtK33uxmoiqyiOrq9SPyNtOGpw//5AsJIFHjeSLgRAAAAAElFTkSuQmCC";
  string private constant FRONT_DOCTOR =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAIVBMVEUAAADy8vL09PSournu7u4VbrgSYKHH2dnW4+NNTU3p6elNMf8JAAAAAXRSTlMAQObYZgAAAIBJREFUGNOtz8ENwjAMBdCPlAFqk0TiaCsLVOoAaTCHcssIkdiBEViEQQnJCODTk/1ly8CfimVdThsLlNdQN1HQ+RrbU2igvogglyM0TwzhFNohHZpiLcpQ8aEWVuzWR8U8zHzssL77mxlH6PbQiexoQLObnQTMzBu4D2TA/fzWB4aNEdL4EWwpAAAAAElFTkSuQmCC";
  string private constant FRONT_SCARF =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAAlkck0fqUTXHy1QV4JAAAAAXRSTlMAQObYZgAAACBJREFUCNdjYCAWRFYBiddzQUxLEMEHIjhBBA/RZpAOADMCAriGZfwcAAAAAElFTkSuQmCC";

  address public tops2;

  constructor(address _tops2) {
    tops2 = _tops2;

    _tiers = [
      500,
      1000,
      1400,
      1800,
      2100,
      2400,
      2700,
      3000,
      3300,
      3600,
      3900,
      4200,
      4500,
      4800,
      5100,
      5400,
      5700,
      6000,
      6300,
      6600,
      6900,
      7200,
      7500,
      7800,
      8100,
      8300,
      8500,
      8700,
      8900,
      9100,
      9290,
      9470,
      9620,
      9720,
      9820,
      9870,
      9920,
      9970,
      9990,
      10000
    ];
  }

  function getName(uint256 traitIndex)
    public
    view
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return "Strappy Top";
    } else if (traitIndex == 2) {
      return "Chef";
    } else if (traitIndex == 3) {
      return "Prehistoric";
    } else if (traitIndex == 4) {
      return "T-Shirt Black";
    } else if (traitIndex == 5) {
      return "T-Shirt White";
    } else if (traitIndex == 6) {
      return "T-Shirt Blue";
    } else if (traitIndex == 7) {
      return "Vertical Red";
    } else if (traitIndex == 8) {
      return "Vertical Green";
    } else if (traitIndex == 9) {
      return "Vertical Orange";
    } else if (traitIndex == 10) {
      return "Turtleneck Black";
    } else if (traitIndex == 11) {
      return "Turtleneck Orange";
    } else if (traitIndex == 12) {
      return "Stripe Red";
    } else if (traitIndex == 13) {
      return "Stripe Blue";
    } else if (traitIndex == 14) {
      return "Stripe Orange";
    } else if (traitIndex == 15) {
      return "Suit";
    } else if (traitIndex == 16) {
      return "Lumberjack";
    } else if (traitIndex == 17) {
      return "Cowboy";
    } else if (traitIndex == 18) {
      return "High-vis Vest";
    } else if (traitIndex == 19) {
      return "Police";
    } else if (traitIndex == 20) {
      return "Doctor";
    } else if (traitIndex == 21) {
      return "Scarf";
    } else {
      return ITrait(tops2).getName(traitIndex);
    }
  }

  function getSkinLayer(uint256 traitIndex, uint256)
    public
    view
    override
    returns (string memory layer)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return STRAPPY_TOP;
    } else if (traitIndex == 2) {
      return CHEF;
    } else if (traitIndex == 3) {
      return PREHISTORIC;
    } else if (traitIndex == 4) {
      return TSHIRT_BLACK;
    } else if (traitIndex == 5) {
      return TSHIRT_WHITE;
    } else if (traitIndex == 6) {
      return TSHIRT_BLUE;
    } else if (traitIndex == 7) {
      return VERTICAL_RED;
    } else if (traitIndex == 8) {
      return VERTICAL_GREEN;
    } else if (traitIndex == 9) {
      return VERTICAL_ORANGE;
    } else if (traitIndex == 10) {
      return TURTLENECK_BLACK;
    } else if (traitIndex == 11) {
      return TURTLENECK_ORANGE;
    } else if (traitIndex == 12) {
      return STRIPE_RED;
    } else if (traitIndex == 13) {
      return STRIPE_BLUE;
    } else if (traitIndex == 14) {
      return STRIPE_ORANGE;
    } else if (traitIndex == 15) {
      return SUIT;
    } else if (traitIndex == 16) {
      return LUMBER;
    } else if (traitIndex == 17) {
      return COWBOY;
    } else if (traitIndex == 18) {
      return HIGHVIS_JACKET;
    } else if (traitIndex == 19) {
      return POLICE;
    } else if (traitIndex == 20) {
      return DOCTOR;
    } else if (traitIndex == 21) {
      return SCARF;
    } else {
      return ITrait(tops2).getSkinLayer(traitIndex, 0);
    }
  }

  function getFrontLayer(uint256 traitIndex, uint256)
    public
    view
    override
    returns (string memory layer)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return FRONT_STRAPPY_TOP;
    } else if (traitIndex == 2) {
      return FRONT_CHEF;
    } else if (traitIndex == 3) {
      return FRONT_PREHISTORIC;
    } else if (traitIndex == 4) {
      return FRONT_TSHIRT_BLACK;
    } else if (traitIndex == 5) {
      return FRONT_TSHIRT_WHITE;
    } else if (traitIndex == 6) {
      return FRONT_TSHIRT_BLUE;
    } else if (traitIndex == 7) {
      return FRONT_VERTICAL_RED;
    } else if (traitIndex == 8) {
      return FRONT_VERTICAL_GREEN;
    } else if (traitIndex == 9) {
      return FRONT_VERTICAL_ORANGE;
    } else if (traitIndex == 10) {
      return FRONT_TURTLENECK_BLACK;
    } else if (traitIndex == 11) {
      return FRONT_TURTLENECK_ORANGE;
    } else if (traitIndex == 12) {
      return FRONT_STRIPE_RED;
    } else if (traitIndex == 13) {
      return FRONT_STRIPE_BLUE;
    } else if (traitIndex == 14) {
      return FRONT_STRIPE_ORANGE;
    } else if (traitIndex == 15) {
      return FRONT_SUIT;
    } else if (traitIndex == 16) {
      return FRONT_LUMBER;
    } else if (traitIndex == 17) {
      return FRONT_COWBOY;
    } else if (traitIndex == 18) {
      return FRONT_HIGHVIS_JACKET;
    } else if (traitIndex == 19) {
      return FRONT_POLICE;
    } else if (traitIndex == 20) {
      return FRONT_DOCTOR;
    } else if (traitIndex == 21) {
      return FRONT_SCARF;
    } else {
      return ITrait(tops2).getFrontLayer(traitIndex, 0);
    }
  }

  function _getLayer(
    uint256,
    uint256,
    string memory
  ) internal pure override returns (string memory layer) {
    return "";
  }
}
