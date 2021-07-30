### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 9b7807e6-dc3e-11eb-0f5d-c9b81d4cf5b5
begin
	import Pkg
	Pkg.activate()
	
	using Revise
	using AstroTime, Measurements, EarthOrientation, Plots, BenchmarkTools
	using PlutoUI
	import Dates, ERFA, PyPlot
	PyPlot.svg(true)
	EarthOrientation.update()
end

# ╔═╡ 96f6bc01-e621-46aa-a3e5-57015b9c4e5b
html"<button onclick='present()'>present</button>"

# ╔═╡ d0fc98d1-d261-4a0b-b610-4819b4b56870
md"""
# A Short History of AstroTime.jl
Hello JuliaCon, my name is Helge Eichhorn. I am a software engineer at Telespazio Germany where I work on Space Mission Analysis and Design Tools and today I am going to tell you the short history of AstroTime.jl. First of all..."""

# ╔═╡ 64b85a57-1b94-4310-8c21-11e58bda1d9e
md"""
## What is AstroTime.jl?
In short, AstroTime.jl is an MIT-licensed library which gives you a high-accuracy `DateTime`-like data type that also supports different time scales. You might ask yourself...
"""

# ╔═╡ 4b00a62c-6d5f-413a-a8f7-8c87675ffc29
md"""
## What does that mean? Why would I even want different time scales?
Excellent question! But first, let's go back to the beginning.

[Stock footage - Big Bang CGI]

Okay, I meant the beginning of AstroTime.jl not the beginning of time.
But on the other hand, why not?

We will use the time at which I am recording this presentation as the starting point.
"""

# ╔═╡ 6bd1ccfa-f269-4f9d-8683-63bc10456d8a
today = now(TAIEpoch)

# ╔═╡ 97128ecc-2a60-4afe-b1e1-0cb76829129b
md"""
We will then define the age of the universe which is around 13.772 billion years.
"""

# ╔═╡ 0cc58f90-6284-4de4-92b5-3d56a85d2254
age_of_the_universe = 13.772e9years

# ╔═╡ 627bd6d6-ad82-44c4-811d-fdb095213844
md"""
So finally the date of the big bang is `today` minus the age of the universe.
"""

# ╔═╡ 4deefa9c-a50b-4bff-8c74-6c65a7864b76
big_bang = today - age_of_the_universe

# ╔═╡ f269b1c7-c924-4764-9f68-d0d5f2879705
md"""
This calendrical representation is of course not very meaningful on such a large time scale. I will talk more about calendar troubles later. Let's have a look at the Julian Date instead which is a continuous count of days since a specific epoch.
"""

# ╔═╡ d9724b53-f119-44fa-a4ba-3a7bd51f35c7
j2000(big_bang)

# ╔═╡ f377dd26-723d-4012-b1bf-26767e2194c1
md"""
This means the Big Bang occured roughly 5 trillion days before January 1st of the year 2000.

Claiming that the Big Bang occured at that exact moment might also be a bit of a stretch. Let's add some uncertainty with `Measurements.jl` then. More appropriately, the approximate age of the universe is 13.772 billion plus-minus 0.04 billion years.
"""

# ╔═╡ 25eea271-8589-497e-9279-7ed69beb6b2e
approximate_age_of_the_universe = (13.772e9 ± 0.040e9) * years

# ╔═╡ 06aa7a0d-fc27-4051-b3d5-923ef4f9e07b
md"""
With that we can calculate an approximate date for the Big Bang:
"""

# ╔═╡ 88d03e9b-560c-4b27-9a6b-2d6aeaf49946
approximate_big_bang = today - approximate_age_of_the_universe

# ╔═╡ cda813db-2975-491a-9cde-173ce82b2ad8
md"""
The calendar representation is still not helpful but the Julian Date reveals the uncertainty.
"""

# ╔═╡ e896ac12-0872-41c7-8073-da01f98ccb65
j2000(approximate_big_bang)

# ╔═╡ dc3ea266-258e-4f2e-8f85-eccfcd3ee4a2
md"""
Let's use the overly confident "exact" Big Bang date for another experiment. According to cosmologists, baryons such as protons and neutrons started forming at about $$10^{-6}$$ seconds after the Big Bang.
"""

# ╔═╡ 4b9b0c5d-bf85-4e4f-ae9e-ebc6abe68bdb
baryons = big_bang + 1e-6seconds

# ╔═╡ 87343448-d6bc-4256-bf7b-1a66945ceaaf
md"""
If we now take this timestamp and add the age of the universe and then substract today, we get back the same $$10^{-6}$$ seconds of elapsed time without any loss in accuracy.
"""

# ╔═╡ 4d8b385a-3b39-4e10-970b-223b96b2238d
baryons + age_of_the_universe - today

# ╔═╡ 2ebda195-3668-4da7-940c-ec9ab90537ad
md"""
Alright, this was a pretty silly example and I am quite sure that this is not how cosmological time works. So let's go forward several billion years to the beginning of AstroTime.jl.
"""

# ╔═╡ f3c30b90-a8df-434d-b522-f1f37ceb7444
md"""
## Part 1 – The Beginning

Whether you are tracking celestial phenomena or you are navigating a spacecraft to another world, you need accurate means of time keeping. Even if your needs are more down to Earth, in every field you will need the ability to time events and calculate the elapsed time between them.

At this point everybody realises that doing calculations with our western Gregorian calendar is absolutely insane. Months have different lengths by default and then there is the trouble with leap years.
The fundamental problem is that the Earth needs approximately 365.2422 days to orbit the Sun. By inserting leap years with 366 days the Gregorian calendar aims to make the average year 365.2425 days long to keep the calendar synchronized with Earth's actual revolution. Here is the rule:

> Every year that is exactly divisible by four is a leap year, except for years that
> are exactly divisible by 100, but these centurial years are leap years if they are
> exactly divisible by 400. For example, the years 1700, 1800, and 1900 are not leap
> years, but the years 1600 and 2000 are.[2]
>    — United States Naval Observatory

Messy.

It get's even more complicated if you need to consider historic events. If they occured before the introduction of the Gregorian calendar they are probably given in the preceding Julian calendar but they might also use a proleptic Gregorian calendar which is extended into the past.

For the record, AstroTime.jl uses the Julian calendar for dates preceding the introduction of the Gregorian calendar and a proleptic Julian calendar for dates before January 1, 1 AD. The `Dates` standard library on the other hand uses a proleptic Gregorian calendar.
"""

# ╔═╡ aee5aaa1-147d-4aa0-9704-d9894c48da28
AstroTime.AstroDates.calendar(AstroTime.Date(-753, 4, 21))

# ╔═╡ 77112dd1-df7e-4d22-83ab-3bc2de031383
AstroTime.AstroDates.calendar(AstroTime.Date(1415, 10, 25))

# ╔═╡ 7a0fe852-ee76-44f7-9f38-e80d40063120
AstroTime.AstroDates.calendar(AstroTime.Date(2012, 2, 14))

# ╔═╡ 339906f0-191f-4c3e-ab04-6fd6f724f4ce
md"""
A solution to this has been independently developed by multiple communities. Instead of using a calendar you just count specified time intervals since a start epoch.

One example is Unix time which counts seconds since Midnight on January 1st, 1970.

Another are Julian Dates which I have mentioned in the introductory example and are used by astronomers and astronautical engineers.

**Note:** Julian Dates should not be confused with the Julian calendar.
"""

# ╔═╡ cc006259-cac2-43ca-a77c-1b1a0ce6be63
Dates.datetime2unix(Dates.DateTime(today))

# ╔═╡ b3e8edf7-1b2f-4244-81b5-7ac9473c2e78
julian(today)

# ╔═╡ 55b4aa58-634e-4f79-853e-876a0f2156af
modified_julian(today)

# ╔═╡ f8353359-7638-420b-bf66-54a3df8565dc
j2000(today)

# ╔═╡ 9ed6cdae-902d-4233-95bf-d6b54bbd697f
md"""
They count days starting at noon on Monday, January 1, 4713 BC, in the proleptic Julian calendar. There are other variants that start at different epochs such as the aforementiond `J2000` which starts at January 1, 2000.

Why do they start at noon? Because the date shift should not be in the middle of the night when astronomers are out making their observations.

The advantages for doing math are clear. If you want to determine the time interval between two dates, you can directly subtract the Julian Dates from another and you do not need to care about whether or not there is a leap day in between.
"""

# ╔═╡ 29e00530-aa7a-4318-9b79-6b54f287d5ed
jd1 = julian(TAIEpoch(2020, 2, 28))

# ╔═╡ ce6168f3-d620-4e5e-8e46-51bea8cceb8c
jd2 = julian(TAIEpoch(2020, 3, 1))

# ╔═╡ 681586c1-0ec4-43b2-aebe-8d8004d92bb2
jd2 - jd1

# ╔═╡ 5efd6405-bf02-4dc1-87f5-42c4851b1b7c
md"""
The major disadvantage is also obvious. Julian Dates and also Unix timestamps are unparseable by most humans because they lack the calendarial structure that we are used to.

In the end, you need both.

Thus, my first experiments and incidentally also some of my first attempts with Julia while I was an intern at the ESA's European Space Operations Centre, tried to combine these two representations. This was back in 2013 before the introduction of the excellent `Dates` standard library. As you can see by looking at the code, I was not really certain about the data model and whether or not this was a good idea. *Spoiler alert:* It wasn't.
"""

# ╔═╡ bb827858-9f12-470e-86e6-0771c0524797
Show(MIME"image/png"(), read("figures/code1.png"))

# ╔═╡ 13d820b6-83f8-4d23-b894-d22d2413d00b
md"""
At this point in time, I was heavily invested in the Scientific Python ecosystem and still on the edge about Julia. I was certain that Julia would be an excellent fit for space science and engineering but humbled by the magnitude of the task of building such an ecosystem from scratch I started a PhD in a different field (*spoiler alert:* also not a great idea), worked on Python things, and procrastinated for a few years.
"""

# ╔═╡ 5a2ca7a1-13b6-45e7-8e8d-81c5efb92fdd
md"""
## Part 2 – Time Scales

Fast forward to early 2016. Two other guys and myself had just tried to merge our Python-based astrodynamics libraries into the one true library to rule them all. After a promising start we got hampered by clashing design sensibilities, bikeshedding about object hierarchies, and, what bothered me the most, massive performance problems everytime we tried to introduce an abstraction that went beyond a NumPy array. As a result we lost steam and the project was gradually abandoned.

Based on this experience, I decided to go all in with Julia. This time I did not try to write everything from scratch but tried to reuse as much existing code and know-how from other languages as possible. One of the nicest parts of working with Python was `Astropy`.

I was used to dealing with Julian Dates in the form of raw floating point values but Astropy provides a nice abstraction for dealing with all sorts of astronomical dates in form of the `Time` class.

```python
import numpy as np
from astropy.time import Time

times = ['1999-01-01T00:00:00.123456789', '2010-01-01T00:00:00']
t = Time(times, format='isot', scale='utc')
```

Building something as powerful in Julia would be the first step. But before we can talk about the next iteration of the data model, we need to discuss one of the initial questions: Why do we need different time scales at all?

According to Newtonian mechanics we only need to measure hard enought to find the one true time:

> Absolute, true and mathematical time, of itself, and from its own nature flows equably without regard to anything external, [...]
>	– Isaac Newton, Principia (1687)

This turned out to be a wicked problem. But 300 years later we are approaching this ideal with atomic clocks. An optical lattice strontium clock will gain or lose less than a second in 15 billion years which is longer than the age of the universe, as previously discussed.

International Atomic Time or TAI (from French "temps atomique international"), the weighted average of over 400 atomic clocks worldwide, gives us a high-precision time standard and our civil Coordinated Universal Time or UTC is also based on it. We also have global satellite navigation constellations such as GPS and Galileo which are essentially atomic clocks flying in space. This means that everybody with a modern smartphone has instant access those highly accurate clocks.

All is well? Not quite. Our daily lives are still governed by solar time and the passing of day and night which is defined by the rotation of the Earth. Unfortunately, Earth's rotation is much less stable than an atomic clock.

The main time scale in use based on Earth's rotation is Universal Time and more specifically UT1. The difference between TAI and UT1 is a measured quantity and one of the Earth Orientation Parameters published by the International Earth Rotation and Reference Systems Service (IERS). We can access these parameters with `EarthOrientation.jl`. 
"""

# ╔═╡ c00d5a3e-54b9-483a-96b8-efc2bc4a8667
ep_rng = TAIEpoch(1975,1,1):1days:today

# ╔═╡ 49ae6271-8d46-4b2c-be77-7bc0c648091f
ΔUT1_TAI = getΔUT1_TAI.(value.(julian.(ep_rng)));

# ╔═╡ f8d73ace-06fe-4279-9e96-60ac72d6b71c
begin
	PyPlot.plot(Dates.DateTime.(ep_rng), ΔUT1_TAI, "tab:blue")
	PyPlot.gcf()
end

# ╔═╡ 5a609cc3-d9c3-45dd-b1cf-622da4f80146
md"""
We can see that TAI is ahead of UT1 because Earth's rotation is getting slower. This means that without countermeasures UTC which is based on atomic time would drift away from UT1 long term.

This is prevented by inserting leap seconds into the UTC time scale which keeps the difference between UTC and UT1 under 0.9 seconds.

If we plot this difference over time, the jumps become clearly visible.
"""

# ╔═╡ 83fdd3d8-aa97-4f26-bf55-44daf62af476
ΔUT1 = getΔUT1.(value.(julian.(ep_rng)));

# ╔═╡ e6b570fa-a15e-4510-a282-c71e4b590668
begin
	PyPlot.clf()
	PyPlot.plot(Dates.DateTime.(ep_rng), ΔUT1, "tab:blue")
	PyPlot.gcf()
end

# ╔═╡ c84dc04c-7f43-4f5b-b07a-1aaed19b7d10
md"""
I'll do a little bit of foreshadowing by saying that leap seconds have been the bane of my existence for the past few years and we will talk about those troubles later.

In summary, we need these three time scales to accurately deal with time on Earth. How does the picture change if we go to outer space?

In the previous discussion, I omitted an important detail about TAI. Namely that it is based on the passage of "proper time" on  Earth's geoid, an idealized representation of Earth's surface.

Why does that matter? Because thanks to Albert Einstein's theory of relativity and subsequent experiments proving it we know today that there is no absolute Newtonian time. Time is relative.

Due to gravitational time dilation a clock that is closer to a source of gravity will tick slower than a clock that is farther away. There is also time dilation due to relative velocity. A clock that is moving relative to a clock at rest will be measured to tick slower.

If you think about the implications of this when moving around the Solar System it gets complicated pretty fast.

To deal with these relativistic issues astronomers have defined additional time scales and the transformations between them:

- **Terrestrial Time (TT):** For observations from Earth's surface. Identical to TAI except for a fixed offset.
- **Geocentric Coordinate Time (TCG, from "Temps-Coordonnée Géocentrique"):** The time experienced by a clock at rest in a coordindate frame moving with the center of the Earth but unaffected by Earth's gravity and rotation.
- **Barycentric Coordinate Time (TCB, from "Temps-Coordonnée Barycentrique"):** The time experienced by a clock at rest in a coordindate frame moving with the center of mass of the Solar System but unaffected by the gravity of the Solar System.
- **Barycentric Dynamical Time (TDB, from "Temps Dynamique Barycentrique"):** Which is defined as a linear scaling from TCB and takes into account time dilation.

Thus, my goal for what would become AstroTime.jl was set, deal with the zoo of astronomical time scales in a human-friendly manner while taking inspiration from Astropy.

Internally, Astropy uses the ERFA C library which is an open-source derivative of the Standards of Fundamental Astronomy (SOFA) library published by the International Astronomical Union for most of its date and time functionality. Thanks to Mike Nolta and the JuliaAstro community, ERFA.jl, a Julia wrapper for ERFA, was available at this time and I decided to take the same approach.

ERFA models dates as two-part Julian dates. This means that a date consists of two arbitrarily split `Float64` values so that `jd = jd1 + jd2`. For example, by splitting between the integral day number and the fractional part of day.
"""

# ╔═╡ 127301a1-8d09-4881-a4cd-bdeca5cd3a8f
utc1, utc2 = ERFA.dtf2d("UTC", 2018, 2, 6, 20, 45, 0.0)

# ╔═╡ 4723271f-a96f-4fa9-aba3-ccb9207561db
md"""
This approach increases the accuracy because current Julian Dates are large numbers and thus more digits are available for the fractional part if the day number has been subtracted.

This was how my initial rewrite looked like. As you can see, I had just discovered metaprogramming. A dangerous time for a young padawan...
"""

# ╔═╡ dcd8c12a-3e80-41c7-8467-1a6538c95616
Show(MIME"image/png"(), read("figures/code2.png"))

# ╔═╡ 204dd602-470d-4952-9909-b115724c8620
md"""
While none of the code from this era has survived until the present day, an important idea that endured crystallized during this time.

**The computer should be in charge of keeping track of time scales.**

In the classical ERFA approach this is the user's job:
"""

# ╔═╡ 95b02b29-d2db-427e-b535-0c84dcfc493f
tai1, tai2 = ERFA.utctai(utc1, utc2)

# ╔═╡ 706e344d-4750-4536-8b2a-c82e749f581d
tt1, tt2 = ERFA.taitt(tai1, tai2)

# ╔═╡ e6333e26-0e8b-4191-9517-7bfb5df4c296
tcg1, tcg2 = ERFA.tttcg(tt1, tt2)

# ╔═╡ 50ff0c6d-4e59-48a7-8af4-2eac7cc250fe
md"""
This means that the user needs to be aware of the relationships between time scales.
"""

# ╔═╡ 3a814113-a528-4702-a3c0-728c9a5212ba
Show(MIME"image/png"(), read("figures/graph.png"))

# ╔═╡ 81d2aa16-a205-4f8c-a2ec-4ec0a35db927
md"""
Astropy's `Time` class already abstract this away but AstroTime.jl takes it one step further by leveraging Julia's expressive type system. All iterations of the `Epoch` type that followed have used the time scale as a type parameter:

```julia
abstract type TimeScale end

struct Epoch{T<:TimeScale}
	scale::T
	...
end
```

This enables the Julia compiler to figure out the necessary transformations between time scales automatically and we can directly convert to TCG without any intermediary steps.
"""

# ╔═╡ 2b32d793-3122-4a6c-a184-02ed3e3ff43e
tai = from_utc(2018, 2, 6, 20, 45, 0.0, scale=TAI)

# ╔═╡ c296abea-4511-4933-897d-acd597892221
typeof(tai)

# ╔═╡ 65dcf800-ede6-44db-8085-520549a8deb9
tcg = TCGEpoch(tai)

# ╔═╡ 93287052-6673-4245-b691-124d553e50f3
typeof(tcg)

# ╔═╡ e6d1c9ce-fab9-47b7-8dcc-844191d5489b
value(julian(tcg)) ≈ tcg1 + tcg2

# ╔═╡ 542b1bd3-39b4-4880-aef6-2aca13e3e420
md"""
This simple API has proven to be very powerful and has remained unchanged till today.

However, at this point the `Epoch` code was still part of `Astrodynamics.jl` which I presented at my first JuliaCon in Boston in 2016. Shortly thereafter I decided to put the time code into a separate `AstronomicalTime.jl` package which led to me being contacted by Kyle Barbary and Mosé Giordano from JuliaAstro and joining forces with them.

`AstronomicalTime.jl` was moved to `JuliaAstro` and renamed to `AstroTime.jl`. I also quit my job in academia and returned to the space industry.

With a solid foundation based on ERFA in place, we decided to start porting the relevant parts of ERFA from C to Julia. Our GSOC student Prakhar Srivastava took care of that and more in the summer of 2018.

All was well! Or was it?
"""

# ╔═╡ f419a06d-3dbc-41ab-847d-f7dc2a1f74ad
md"""
## Part 3 – Standing on the Shoulders of Giants

In mid 2018, my colleague Bernard Godard who is a Flight Dynamics Engineer at ESOC discovered the library and did some experiments. He used the calculation of transmission times for an interplanetary spacecraft such as Voyager 2 where there is a considerable amount of light time delay because of the large distances as an example.
"""

# ╔═╡ c77f4560-f501-45d8-b627-cb9f743125ec
reception_time = TDBEpoch("2021-07-01T00:00:00.00")

# ╔═╡ da3560e2-366e-4264-ada3-5fd100f0e78d
# round trip light time
rtlt_a = seconds(1.5days)

# ╔═╡ a128db96-ef58-474d-8815-b1015337dfb3
rtlt_b = rtlt_a + 1e-6seconds

# ╔═╡ 8a5f595c-8ac2-4f93-8e99-03bed6429387
velocity = 15.341 # km/s

# ╔═╡ b400d692-e232-4852-8e07-9a6b96bfd938
distance_travelled = value(seconds(rtlt_b - rtlt_a)) * velocity # km

# ╔═╡ d0abad31-b745-4fd9-9725-2ca2544c177d
transmission_time_a = reception_time + rtlt_a

# ╔═╡ b2230ea5-bf63-44f1-babe-0684207871fe
transmission_time_b = reception_time + rtlt_b

# ╔═╡ 15bfe97a-4ef7-4fb7-9463-574385c068c8
transmission_time_b - transmission_time_a

# ╔═╡ ee3cfe44-40f3-4cd6-942a-35cc0ac81381
md"""
The current version of AstroTime.jl preserves the time difference accurately. But back then the result was different...
"""

# ╔═╡ e80e6b32-c6f5-4ad1-bb13-0807686212ce
Show(MIME"image/png"(), read("figures/issue.png"))

# ╔═╡ b387b901-4ce1-4022-995d-999f5b000d4e
md"""
Since deep space exploration is one of my favorite topics and Julia shall become a multiplanetary programming language one day, this was not acceptable. Back to the drawing board...

After some discussions, we decided to adopt the same high-accuracy internal representation of dates that the open-source Java flight dynamics library Orekit uses. The result looked somewhat like this.

```julia
struct Epoch{T<:TimeScale}
	scale::T
	tai_second::Int64 # Integral seconds since 2000-01-01T00:00:00.00 TAI
	fraction::Float64 # Fraction of the current second
end
```

Which meant another rewrite of the library was in order. The first version was a straight port of the `AbsoluteDate` class and other auxiliary classes from Java to Julia.

The name of that class should give one pause though. The trick the Orekit authors apply is to convert all dates internally to the TAI time scale. This makes it easier to deal with the conversions between scales because you are dealing with 1-to-N conversions and not M-to-N conversions and it also avoids troubles with leap seconds because TAI is a nice and uniform time scale. It is also a reasonable thing to do if you are dealing with spacecraft in orbit around Earth.

Not so much for deep space missions, though, as Bernard informed me after I presented my rewrite to him. The problem boils down to gravitational time dilation again. If we consider a spacecraft far away from Earth, it will be in a completely different part of the Solar System's gravity well and experience a different gravitational potential than a spacecraft close Earth. Thus, there would be no straightforward relation between the proper relativistic time experienced by the spacecraft's clock and TAI on Earth.

Turns out an `AbsoluteDate` does not really work when everything is relative.

Another iteration later in early 2020, we had successfully moved back to relative transformations.

```julia
struct Epoch{T<:TimeScale}
	scale::T
	second::Int64 # Integral seconds since 2000-01-01T00:00:00.00 in `scale`
	fraction::Float64 # Fraction of the current second
end
```

And then leap seconds reared their ugly head again...

The problem with UTC is that there is a discontinuity in the time scale everytime a leap second is introduced. We learned the hard way that this created ambiguities in our data model during around leap seconds. Let me show you the problem:

| TAI | UTC | TAI second | Offset | UTC second |
|:----|:-----|:------|:------------|:--------------|
| 2017-01-01T00:00:35.000 | 2016-12-31T23:59:59.000 | 536500835 | 36 | 536500835 - 36 = 536500799 |
| 2017-01-01T00:00:36.000 | 2016-12-31T23:59:60.000 | 536500836 | **36/37** | **536500836 - 36 = 536500800 / 536500836 - 37 = 536500799** |
| 2017-01-01T00:00:37.000 | 2017-01-01T00:00:00.000 | 536500837 | 37 | 536500837 - 37 = 536500800 |
| 2017-01-01T00:00:38.000 | 2017-01-01T00:00:01.000 | 536500838 | 37 | 536500838 - 37 = 536500801 |

At this point, we had two choices: change the storage format once again which would incur another complete rewrite or relegate UTC to be an I/O format.

We chose the latter. Sorry UTC, but from now on this is a uniform-time-scales-only club...
"""

# ╔═╡ fac44891-7af3-447a-b930-fd1711a096f0
ep = from_utc(2018, 2, 6, 20, 45, 0.0) # This used to be `UTCEpoch(...)`

# ╔═╡ 5cfb21ed-dc03-4c37-94ee-bb8e3436dca3
typeof(ep)

# ╔═╡ a30edc9f-7f22-4bcd-9623-31e20e3ee08a
to_utc(String, ep)

# ╔═╡ 9badb9ee-9a46-4a62-b70d-616679f47af4
md"""
## Part 4 – Seeing Further

This is where we are today. We would not have been able to get this far without open source because we took inspiration and concrete implementation details from many different sources.

> If I have seen further it is by standing on the shoulders of Giants.
> – Isaac Newton

I want to use this part of the talk to highlight these giants and show where we have been able to make improvements because of the headstart they gave us.

I also want to give you ideas how you could use AstroTime.jl even if your goal is not to explore distant worlds.

### Astropy & Orekit

I have already talked at length about how Astropy and Orekit served as inspirations and starting points for AstroTime.jl's implementation. The founders of both projects are pioneers of the space science open-source community and doing it a great service.

Thanks to Julia, we have been able to surpass these projects in terms of performance. The following conversion does four separate conversion steps in a matter of a few hundred nanoseconds.
"""

# ╔═╡ bc10b3a4-f3ff-41d6-a4a4-1fc472015fd0
@benchmark TCBEpoch($today)

# ╔═╡ 1b1b43ed-893f-4e09-a289-698ab66d3107
md"""
As of this month, we have also been able to improve upon the accuracy of Orekit, which is another great milestone.

### AccurateArithmetic.jl

We achieved this by using error-free transforms wherever we can and also by tracking the associated floating point error.

```julia
struct Epoch{S<:TimeScale, T} <: Dates.AbstractDateTime
    scale::S
    second::Int64
    fraction::T
    error::T
    function Epoch{S}(second::Int64, fraction::T, error::T=zero(T)) where {S<:TimeScale, T<:AbstractFloat}
        return new{S, T}(S(), second, fraction, error)
    end
end
```

The algorithms were adapted from AccurateArithmetic.jl.

### Chrono.jl

You have seen me use the shorthand syntax for time periods.
"""

# ╔═╡ 83050f51-b7bf-48c0-8e04-21e4c1b0a354
today + 5seconds

# ╔═╡ 5d794ce9-6a63-404d-b588-d4795a8af199
md"""
I adopted this idea from the [Chrono.jl](https://github.com/FugroRoames/Chrono.jl) prototype by Andy Ferris and Chris Foster.

### Dates

AstroTime.jl is reusing all of the parsing and formatting machinery of the excellent `Dates` standard library and is generally highly compatible with it.

You can easily convert from `DateTime` to `Epoch` and vice-versa. Although, please note that `DateTime` only supports millisecond accuracy.
"""

# ╔═╡ 3ff48e3d-f4c1-4e4f-8d2e-f5b94f084366
ep_from_dt = TAIEpoch(Dates.DateTime(2018, 2, 6, 20, 45, 0, 0))

# ╔═╡ 7bd69f4b-fc08-42e9-a9b2-2177b55574fe
dt_from_ep = Dates.DateTime(ep_from_dt)

# ╔═╡ a50a4abf-9f2f-4937-a95d-70792f1698e0
md"""
There is currently an [issue](https://github.com/JuliaLang/julia/issues/37579) limiting the parser from `Dates` to milliseconds even though `Dates.Time` does support nanoseconds.

We have a workaround for that...
"""

# ╔═╡ fbb110b9-9651-4c66-ad5d-9bfddefaa2f2
Dates.Time(TAIEpoch("2018-02-06T20:45:00.123456789"))

# ╔═╡ cfdc0104-2d25-4d62-9056-fa0a4ae20871
md"""
We have also added a few other small features that you might find useful.

For example, the day-of-year format for timestamps:
"""

# ╔═╡ ff63332f-13b6-4556-a1ee-0a3886344034
doy_ep = TAIEpoch("2018-37T20:45:00", Dates.dateformat"yyyy-DDDTHH:MM:SS.fff")

# ╔═╡ 345ec872-d1f0-4c58-87d9-22b3fd6f07a7
md"""
Or the aforementioned support for the Julian and proleptic Julian calendars.

We hope to be able to upstream a few of these improvements to `Dates` in the future.

To cut a long story short: AstroTime.jl should be able to serve as a drop-in replacement for Dates if you need higher resolution, deal with leap seconds or want to fly a spacecraft to Jupiter. And if not, I want to know...
"""

# ╔═╡ c3f5eeeb-2a6c-43be-b53b-ab435a45baa5
md"""
## Part 5 – The Undiscovered Country

Where do we go from here?

As of now, I consider AstroTime.jl to be fairly complete and fit for purpose. We have been using it in production for a while. Unfortunatly not for flying spacecraft to Jupiter but at least for designing missions to the Moon.

Even though there has been a lot of turmoil about the internal representations over the last few years, the public API has been remarkably stable. Thus, I am planning for the next major version to be 1.0.

Finally, let me say thank you for your attention and I hope that you found this presentation relatively interesting (pun intended). I encourage you to give AstroTime.jl a try by following the tutorial and you can find me on GitHub (@helgee), Discourse (@helgee), Twitter (@helge_e), and sometimes Slack and Zulip where I will be waiting for your feedback.

Thanks again and I hope to see you all in person next year.
"""

# ╔═╡ Cell order:
# ╠═9b7807e6-dc3e-11eb-0f5d-c9b81d4cf5b5
# ╟─96f6bc01-e621-46aa-a3e5-57015b9c4e5b
# ╟─d0fc98d1-d261-4a0b-b610-4819b4b56870
# ╟─64b85a57-1b94-4310-8c21-11e58bda1d9e
# ╟─4b00a62c-6d5f-413a-a8f7-8c87675ffc29
# ╠═6bd1ccfa-f269-4f9d-8683-63bc10456d8a
# ╟─97128ecc-2a60-4afe-b1e1-0cb76829129b
# ╠═0cc58f90-6284-4de4-92b5-3d56a85d2254
# ╟─627bd6d6-ad82-44c4-811d-fdb095213844
# ╠═4deefa9c-a50b-4bff-8c74-6c65a7864b76
# ╟─f269b1c7-c924-4764-9f68-d0d5f2879705
# ╠═d9724b53-f119-44fa-a4ba-3a7bd51f35c7
# ╟─f377dd26-723d-4012-b1bf-26767e2194c1
# ╠═25eea271-8589-497e-9279-7ed69beb6b2e
# ╟─06aa7a0d-fc27-4051-b3d5-923ef4f9e07b
# ╠═88d03e9b-560c-4b27-9a6b-2d6aeaf49946
# ╟─cda813db-2975-491a-9cde-173ce82b2ad8
# ╠═e896ac12-0872-41c7-8073-da01f98ccb65
# ╟─dc3ea266-258e-4f2e-8f85-eccfcd3ee4a2
# ╠═4b9b0c5d-bf85-4e4f-ae9e-ebc6abe68bdb
# ╟─87343448-d6bc-4256-bf7b-1a66945ceaaf
# ╠═4d8b385a-3b39-4e10-970b-223b96b2238d
# ╟─2ebda195-3668-4da7-940c-ec9ab90537ad
# ╟─f3c30b90-a8df-434d-b522-f1f37ceb7444
# ╠═aee5aaa1-147d-4aa0-9704-d9894c48da28
# ╠═77112dd1-df7e-4d22-83ab-3bc2de031383
# ╠═7a0fe852-ee76-44f7-9f38-e80d40063120
# ╟─339906f0-191f-4c3e-ab04-6fd6f724f4ce
# ╠═cc006259-cac2-43ca-a77c-1b1a0ce6be63
# ╠═b3e8edf7-1b2f-4244-81b5-7ac9473c2e78
# ╠═55b4aa58-634e-4f79-853e-876a0f2156af
# ╠═f8353359-7638-420b-bf66-54a3df8565dc
# ╟─9ed6cdae-902d-4233-95bf-d6b54bbd697f
# ╠═29e00530-aa7a-4318-9b79-6b54f287d5ed
# ╠═ce6168f3-d620-4e5e-8e46-51bea8cceb8c
# ╠═681586c1-0ec4-43b2-aebe-8d8004d92bb2
# ╟─5efd6405-bf02-4dc1-87f5-42c4851b1b7c
# ╟─bb827858-9f12-470e-86e6-0771c0524797
# ╟─13d820b6-83f8-4d23-b894-d22d2413d00b
# ╟─5a2ca7a1-13b6-45e7-8e8d-81c5efb92fdd
# ╠═c00d5a3e-54b9-483a-96b8-efc2bc4a8667
# ╠═49ae6271-8d46-4b2c-be77-7bc0c648091f
# ╠═f8d73ace-06fe-4279-9e96-60ac72d6b71c
# ╟─5a609cc3-d9c3-45dd-b1cf-622da4f80146
# ╠═83fdd3d8-aa97-4f26-bf55-44daf62af476
# ╠═e6b570fa-a15e-4510-a282-c71e4b590668
# ╟─c84dc04c-7f43-4f5b-b07a-1aaed19b7d10
# ╠═127301a1-8d09-4881-a4cd-bdeca5cd3a8f
# ╟─4723271f-a96f-4fa9-aba3-ccb9207561db
# ╟─dcd8c12a-3e80-41c7-8467-1a6538c95616
# ╟─204dd602-470d-4952-9909-b115724c8620
# ╠═95b02b29-d2db-427e-b535-0c84dcfc493f
# ╠═706e344d-4750-4536-8b2a-c82e749f581d
# ╠═e6333e26-0e8b-4191-9517-7bfb5df4c296
# ╟─50ff0c6d-4e59-48a7-8af4-2eac7cc250fe
# ╟─3a814113-a528-4702-a3c0-728c9a5212ba
# ╟─81d2aa16-a205-4f8c-a2ec-4ec0a35db927
# ╠═2b32d793-3122-4a6c-a184-02ed3e3ff43e
# ╠═c296abea-4511-4933-897d-acd597892221
# ╠═65dcf800-ede6-44db-8085-520549a8deb9
# ╠═93287052-6673-4245-b691-124d553e50f3
# ╠═e6d1c9ce-fab9-47b7-8dcc-844191d5489b
# ╟─542b1bd3-39b4-4880-aef6-2aca13e3e420
# ╟─f419a06d-3dbc-41ab-847d-f7dc2a1f74ad
# ╠═c77f4560-f501-45d8-b627-cb9f743125ec
# ╠═da3560e2-366e-4264-ada3-5fd100f0e78d
# ╠═a128db96-ef58-474d-8815-b1015337dfb3
# ╠═8a5f595c-8ac2-4f93-8e99-03bed6429387
# ╠═b400d692-e232-4852-8e07-9a6b96bfd938
# ╠═d0abad31-b745-4fd9-9725-2ca2544c177d
# ╠═b2230ea5-bf63-44f1-babe-0684207871fe
# ╠═15bfe97a-4ef7-4fb7-9463-574385c068c8
# ╟─ee3cfe44-40f3-4cd6-942a-35cc0ac81381
# ╟─e80e6b32-c6f5-4ad1-bb13-0807686212ce
# ╟─b387b901-4ce1-4022-995d-999f5b000d4e
# ╠═fac44891-7af3-447a-b930-fd1711a096f0
# ╠═5cfb21ed-dc03-4c37-94ee-bb8e3436dca3
# ╠═a30edc9f-7f22-4bcd-9623-31e20e3ee08a
# ╟─9badb9ee-9a46-4a62-b70d-616679f47af4
# ╠═bc10b3a4-f3ff-41d6-a4a4-1fc472015fd0
# ╟─1b1b43ed-893f-4e09-a289-698ab66d3107
# ╠═83050f51-b7bf-48c0-8e04-21e4c1b0a354
# ╟─5d794ce9-6a63-404d-b588-d4795a8af199
# ╠═3ff48e3d-f4c1-4e4f-8d2e-f5b94f084366
# ╠═7bd69f4b-fc08-42e9-a9b2-2177b55574fe
# ╟─a50a4abf-9f2f-4937-a95d-70792f1698e0
# ╠═fbb110b9-9651-4c66-ad5d-9bfddefaa2f2
# ╟─cfdc0104-2d25-4d62-9056-fa0a4ae20871
# ╠═ff63332f-13b6-4556-a1ee-0a3886344034
# ╟─345ec872-d1f0-4c58-87d9-22b3fd6f07a7
# ╟─c3f5eeeb-2a6c-43be-b53b-ab435a45baa5
