# Example of process


Few examples of plan uml process


## plan uml example  1

```plantuml
Bob -> Alice : hello
Alice -> Bob : Go Away
```

## plan uml example  2

```plantuml  format="svg"
autonumber "<b>[000]"
Bob -> Alice : Authentication Request
Bob <- Alice : Authentication Response

autonumber 15 "<b>(<u>##</u>)"
Bob -> Alice : Another authentication Request
Bob <- Alice : Another authentication Response

autonumber 40 10 "<font color=red><b>Message 0  "
Bob -> Alice : Yet another authentication Request
Bob <- Alice : Yet another authentication Response

```


## plan uml example 3

```plantuml
start
:Init Phase;
:Transfer Phase;
note right
  long running activity,
  process requires signal to proceed
end note
:Termination Phase;
stop
```

## plan uml example  4


::uml:: format="png" classes="uml myDiagram" alt="My super diagram placeholder" title="My super diagram" width="300px" height="300px"
  Goofy ->  MickeyMouse: calls
  Goofy <-- MickeyMouse: responds
::end-uml::

## image png

Below an example of png image

![process](images/test-process.png)


## image svg

Below an example of svg image

![process](images/test-diagramm-1.svg)



## Equation

The Cauchy-Schwarz Inequality:

\begin{equation*}
\left( \sum_{k=1}^n a_k b_k \right)^2 \leq \left( \sum_{k=1}^n a_k^2 \right) \left( \sum_{k=1}^n b_k^2 \right)
\end{equation*}

### Mathjax 

Example:

$$x = {-b \pm \sqrt{b^2-4ac} \over 2a}.$$


end of document


