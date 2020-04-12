﻿# Copyright (c) 2020 Anton Tykhyy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# data
$inputdata = Invoke-WebRequest "https://covid.ourworldindata.org/data/ecdc/total_cases.csv"|ConvertFrom-Csv -Delimiter ","
$countries = 
@{country="China";country_ua="Китай";from="18/01";color="violet";events=
  @{date="23/01";x=-0.5;y=-0.2;text="Уряд Китаю`nоголошує локдаун Уханю";link="https://www.theguardian.com/world/2020/jan/23/coronavirus-panic-and-anger-in-wuhan-as-china-orders-city-into-lockdown"},
  @{date="07/02";x=-0.4;y=-0.3;text="Уряд Китаю наказує ізолювати`nвсіх осіб із підозрою на коронавірус";link="https://www.dailymail.co.uk/news/article-7977649/China-orders-Wuhan-round-suspected-coronavirus-patients-quarantine-camps.html"}
},
@{country="Italy";country_ua="Італія";from="22/02";color="lightgreen";events=
  @{date="09/03";x=-0.1;y=-0.9;text="Уряд Італії оголошує локдаун";link="https://en.wikipedia.org/wiki/2020_Italy_coronavirus_lockdown"},
  @{date="21/03";x=-0.3;y=-0.5;text="Уряд Італії розширює локдаун, наказує`nзупинити некритичні виробинцтва та бізнеси";link="https://en.wikipedia.org/wiki/2020_Italy_coronavirus_lockdown#Nationwide_expansion"}
},
@{country="Ukraine";country_ua="Україна";from="22/03";color="blue";events=@()}

foreach($d in $countries) {
  $map = @{}
  $arr = $null
  for($i = 3; $i -lt $inputdata.Length; $i++) {
    $shrtdate = ($inputdata[$i].date -as [System.DateTime]).ToString("dd/MM")
    if ($arr -eq $null) {
      if ($shrtdate -ne $d.from) { continue }
      $arr = @()
    }
    $n = $inputdata[$i].($d.country) -as [int]
    $m = $inputdata[$i - 3].($d.country) -as [int]
    if (($n - $m) -lt 10) { Write-Warning "$($d.country) $shrtdate $($n - $m) -lt 10" ; continue }
    $pt   = @{x=[math]::Log($n);y=[math]::Log($n-$m);date=$shrtdate;text="$($d.country_ua), $($shrtdate): всього $n, нових $($n-$inputdata[$i-1].($d.country))"}
    $arr += $pt
    $map[$shrtdate] = $pt
  }
  $d["ptmap"] = $map
  $d["ptarr"] = $arr
}

# presentation
$exponents =
@{color="#f00";dash="0.08 0.02";coef=0.134;text="щодня"},
@{color="#c00";dash="0.08 0.08";coef=0.436;text="щодва дні"},
@{color="#a00";dash="0.04 0.04";coef=1.359;text="щотижня"},
@{color="#800";dash="0.04 0.08";coef=1.980;text="щодва тижні"},
@{color="#400";dash="0.02 0.08";coef=2.706;text="щомісяця"}

function makeAxisValue([int]$i, [double]$offset) {
  $v = [math]::Pow(10, [math]::Floor($i / 3)) * ((0x521 -shr (($i % 3) * 4)) -band 0xF)
  @{val=$v;log=$offset + [math]::Log($v)}
}

function jn($s) {
  ($s|where {$_}|%{$trim=$true}{if($trim){$_.Trim("`n").Trim()}else{$_.Trim("`n")};$trim=$false}) -join "`n"
}

$height = 7.25
$width  = 9.5
$offset =-3.5
$xaxis  = 5..16|%{makeAxisValue $_ $offset}
$yaxis  = 5..13|%{makeAxisValue $_ $offset}
Write-Output @"
<svg xmlns='http://www.w3.org/2000/svg' version='1.1' baseProfile='full' viewBox='-1 -1 $($width+2) $($height+2)' fill='none'>
  <!-- title and axis names -->
  <g fill='black' font-size='0.3' text-anchor='middle'>
    <text transform='translate($($width/2),-0.35)'>Дані* по розвитку епідемій COVID-19 у 3 країнах у вигляді параметричного (<tspan font-style='italic'>не календарного</tspan>) графіка</text>
    <text transform='translate($($width/2),$($height+0.75))'>Кількість зареєстрованих випадків /<a href='https://covid.ourworldindata.org'><tspan>дані Our World in Data</tspan></a>/</text>
    <text transform='translate(-0.85,$($height/2)) rotate(-90)'>Кількість зареєстрованих випадків за попередні 3 дні</text>
  </g>
  <!-- axes -->
  <path stroke='black' stroke-width='0.01' d='M 0 $height L $width $height M 0 $height L 0 0' />
  <clipPath id='plot'><rect x='0' y='0' width='$width' height='$height' /></clipPath>
  <!-- axis ticks -->
  <path stroke='black' stroke-width='0.01' d='$($xaxis|%{" M $($_.log) $height v 0.1"})$($yaxis|%{" M 0 $($height-$_.log) h -0.1"})' />
  <!-- gridlines -->
  <path stroke='#ccc'  stroke-width='0.01' d='$($xaxis|%{" M $($_.log) $height v -$height"})$($yaxis|%{" M 0 $($height-$_.log) h $width"})' />
  <!-- x axis tick labels -->
  <g fill='black' font-size='0.2' transform='translate(0,$($height+0.35))' text-anchor='middle'>
    $(jn ($xaxis|%{"
    <text x='$($_.log)'>$($_.val)</text>"}))
  </g>
  <!-- y axis tick labels -->
  <g fill='black' font-size='0.2' transform='translate(-0.15,0.07)' text-anchor='end'>
    $(jn ($yaxis|%{"
    <text y='$($height-$_.log)'>$($_.val)</text>"}))
  </g>
  <!-- legend -->
  <g transform='translate(0.3,0.4)'>
    <g stroke-width='0.02'>
      $(jn ($countries|%{$y=0}{"
      <path stroke='$($_.color)' d='M 0 $y h 0.5' /><circle fill='$($_.color)' r='0.04' cx='0.25' cy='$y' />";$y += 0.25}))
    </g>
    <g stroke-width='0.01' transform='translate(0,2.1)'>
      $(jn ($exponents|%{$y=0}{"
      <path stroke='$($_.color)' stroke-dasharray='$($_.dash)' d='M 0 $y h 0.5' />";$y += 0.25}))
    </g>
    <g transform='translate(0.55,0.05)' font-size='0.25' fill='black'>
      $(jn ($countries|%{$y=0}{"
      <text y='$y'>$($_.country_ua)</text>";$y += 0.25}))
      <g transform='translate(0,2.1)' font-size='0.2'>
        <g transform='translate(-0.6,-0.25)'>
          <text y='-0.25'>Лінії експоненційного зростання епідемії</text>
          <text>за умови, що кількість випадків подвоюється:</text>
        </g>
        $(jn ($exponents|%{$y=0}{"
        <text y='$y'>$($_.text)</text>";$y += 0.25}))
      </g>
    </g>
  </g>
  <g clip-path='url(#plot)'>
    <!-- plot lines -->
    <g transform='translate(0,$height) scale(1,-1)' stroke-width='0.01'>
      $(jn ($exponents|%{"
      <path stroke='$($_.color)' stroke-dasharray='$($_.dash)' d='M $($_.coef) 0 l $height $height' />"}))
      $(jn ($countries|%{"
      <path stroke='$($_.color)' d='$($_.ptarr|%{$s='M'}{"$s $($offset+$_.x) $($offset+$_.y)";$s=' L'})' />"}))
    </g>
    <!-- plot markers and event labels -->
    <g transform='translate($offset,$(-$offset))' font-size='0.2'>
      $(jn ($countries|%{$d=$_;"
      <g fill='$($d.color)'>
      $(jn ($d.ptarr|%{$i=$d.ptarr.Length}{$i--;"
        <g transform='translate($($_.x),$($height-$_.y))'>
          <circle r='0.04'><title>$($_.text)</title></circle>
          $(if($i % 19 -eq 0){"<text x='0.1' y='-0.1'>$($_.date)</text>"})
        </g>"}))
      </g>
      $(jn ($_.events|%{$pt=$d['ptmap'][$_.date];"
      <g transform='translate($($pt.x),$($height-$pt.y))'>
        <g transform='translate($($_.x-0.05),$($_.y-0.35))' fill='black' text-anchor='end'>
          <a href='$($_.link)'>
            <text>$("$($_.date): $($_.text)".Split("`n")|%{"<tspan x='0' dy='0.25'>$_</tspan>"})</text>
          </a>
        </g>
        <line x1='$($_.x)' y1='$($_.y)' x2='0' y2='0' stroke-width='0.02' stroke='$($d.color)' />
      </g>"}))"}))
    </g>
  </g>
  <!-- remark text -->
  <g font-size='0.2' fill='black' transform='translate($($width/2-2),$($height-1.9))'><text>
    $(@"
    * Кожна точка відповідає кількості зареєстрованих випадків на певну дату.
    Наведіть курсором на точку, щоб побачити дату та інші дані.
    &#160;
    N.B.: Реакція на запровадження заходів проявляється з затримкою,
    яка, вірогідно, пов'язана з інкубаційним періодом (2-14 днів за даними ВОЗ).
    Наприклад, від початку ізолювання осіб із підозрою на коронавірус 07/02
    до різкого зламу лінії розвитку епідемії у Китаї 14/02 минув тиждень.
"@.Split("`n")|%{"<tspan x='0' dy='0.25'>$_</tspan>"})
  </text></g>
</svg>
"@|Out-File -FilePath graph.svg -Force -Encoding UTF8
