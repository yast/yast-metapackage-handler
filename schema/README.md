## One Click Install Specification

Get an overview [here](https://en.opensuse.org/openSUSE:One_Click_Install_Developer).
XML schema definition is documented [here](https://en.opensuse.org/openSUSE:One_Click_Install_specification).

### Schema Conversion

```sh
trang oneclick.rnc oneclick.rng
trang oneclick.rnc oneclick.xsd
```

### XML Validation

```sh
xmllint --noout --relaxng oneclick.rng foo.xml
jing -c oneclick.rnc foo.xml
```
