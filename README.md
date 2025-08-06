# LLM Assisted Database creation:

This project is a shiny app that allows the user to created databases
with the assistance of a LLM. This process consists of JSON schema
creation, selection ofa representative sample with ground truth, prompt
engineering, validation on a random sample, and finally the creation of
the database.

<figure>
<img src="README/Figure_1.jpg" alt="Figure 1: LLM Pipeline Schematic" />
<figcaption aria-hidden="true">Figure 1: LLM Pipeline
Schematic</figcaption>
</figure>

## Who is this for?

This app is specialized for the extraction information from unstructured
text. Unstructured information that is too complex to extract with
regular expression typically requires manual extraction. This process is
slow and not without error. This pipeline allows for the exponential
gains in efficiency with statistically verifiable database accuracy.

## What do I need?

The only required input is a large database of unstructured text from
which you wish to extract information with. This app requires specific
formatting for this text (which will be described in the the examples and
random sampling section).

# JSON Schema Creation:

This section allows you to creat your own json schema. A display of the
schema in its native format will be displayed on the right half of the
screen. This schema allows for the LLMS output to follow precise
formatting. When a schema is properly used, the output database requires
no cleaning and facilitate straight forward analysis.

## Name your schema:

Give you schema a name and give a description (no effect on output but
can be used for reference later so you know what the schema was about).

## Object or Array:

Specify whether you want to extract one object from each unstructured
text or an array. Objects extract a single row of information from a
text, array extract numerous rows.

-   object: database of surgeon name, time, and EBL from a surgery
    report

    <table>
    <thead>
    <tr class="header">
    <th style="text-align: left;">surgeon_name</th>
    <th style="text-align: left;">time</th>
    <th style="text-align: left;">ebl_ml</th>
    </tr>
    </thead>
    <tbody>
    <tr class="odd">
    <td style="text-align: left;">Dr. Smith</td>
    <td style="text-align: left;">2024-08-12</td>
    <td style="text-align: left;">250</td>
    </tr>
    </tbody>
    </table>

-   array: all kidney lesions found in a radiology report

    <table>
    <thead>
    <tr class="header">
    <th style="text-align: left;">lesion_id</th>
    <th style="text-align: left;">location</th>
    <th style="text-align: left;">size_cm</th>
    <th style="text-align: left;">lesion_type</th>
    </tr>
    </thead>
    <tbody>
    <tr class="odd">
    <td style="text-align: left;">1</td>
    <td style="text-align: left;">left kidney</td>
    <td style="text-align: left;">2.3</td>
    <td style="text-align: left;">cyst</td>
    </tr>
    <tr class="even">
    <td style="text-align: left;">2</td>
    <td style="text-align: left;">right kidney</td>
    <td style="text-align: left;">1.5</td>
    <td style="text-align: left;">solid mass</td>
    </tr>
    <tr class="odd">
    <td style="text-align: left;">3</td>
    <td style="text-align: left;">left kidney</td>
    <td style="text-align: left;">0.9</td>
    <td style="text-align: left;">angiomyolipoma</td>
    </tr>
    </tbody>
    </table>

## Object properties:

-   name: name of the property

-   type: string, number, integer

    -   string: free text that can have enumerations, format, or regex
        pattern or nothing restrictions at all.

        -   enumerations: list of possibe choices (`left`, `right`)

        -   format: predefined formats in Java: date-time
            (`2023-04-01T12:00:00Z`), date (`2023-04-01`), time
            (`14:30:00`), email (`user@example.com`), phone
            (`123-456-7891`), hostname (`www.example.com`), ipv4
            (`192.168.1.1`), ipv6 (`2001:0db8::1`), uri
            (`https://example.com`), uuid
            (`550e8400-e29b-41d4-a716-446655440000`), regex
            (`^[A-Z]{3}-\\d{4}$`), byte (`U29mdHdhcmU=`), binary
            (`01010101`), password (`masked input`)

        -   pattern: regex formats that aren’t supported by native json
            can be defined here `(ap) 12 x (ll) 4.5 x (cc) NA` could be
            a valid output of:
            `^(ap)\s(\d+(\.\d)?|NA)\sx\s(ll)\s(\d+(\.\d)?|NA)\sx\s(cc)\s(\d+(\.\d)?|NA)$`.
            This is also a great way to make arrays of strings such as:
            `^(upper|mid|lower)? ?(medial|lateral)? ?(anterior|posterior|midline)?$`
            allowing a string of 1-3 location descriptors always in the
            same order- ie: `upper`, `posterior`, `upper lateral`,
            `mid lateral posterior`, but never `lateral upper`.

    -   number: any number format from integer, floating point, and
        exponential (`4`, `-5.2978`, `4e-5` all supported)

        -   enumerations: list of possible choices (`1`,`2`,`3`,`4`,`5`)

        -   minimum/ maximum: inclusive range by default.

    -   integer: integer specific number format (`1`,`2`,`3`,`4`,`5`)

-   required: If the item cannot be null, then check required. If the
    item can be null, do not check.

## Add/Remove property

If you make a mistake you can add or remove a property. The property
added last will be removed. This can be repeated until all properties
are gone.

## file name:

enter file name for the schema to save as a .json file. Json files are
simply .txt files with specialized formatting. Minor errors can be
corrected in any text editor.

## download the schema:

Download the schema you have created to use in the next steps.

# Selection of a Representative Sample

The next step is to select representative examples that will serve as
ground truth. There is no required number. A minimum of 20 examples is
advised; however, the more heterogeneous your data is the more examples
will be required to truly represent the complexity of the task. These
examples will be used to engineer a prompt. Prepare your examples by
placing them in the first column in an excel file. There should be no
columns names (data in A1:An with n examples).

## input the .json file:

Upload your json schema you created in the previous step. This will auto
populate an example entry tab on the right half of the screen. Each
property will be pulled up as a form. Enumerations will be provided as a
drop down. Properties that allow null will populate a check box.

## input an xlsx file:

Input at least 20 of your representative examples here as the xlsx file.
As a reminder: place examples in the first column in an excel file.
There should be no columns names (data in A1:An with n examples).

## input the data:

-   add row: After you have finished a data row click the `add row`
    button. `Preview` will give you a visual of the data frame as well
    as a json validation message based on your schema. `Valid` rows
    match the schema rules, `Invalid` rows failed validation. The
    specific invalid datapoint(s) will be bookend by question marks
    (`?left?`). For array schemas, you can add multiple rows for each
    example. For object types you can only add one.

-   remove row: removed the last entry and clear the validation logic.
    Redo the entry and it will be revalidated.

## arrows:

Move forward or backward from each example. The json data and validation
will be saved for each example.

## File names:

enter file names without extensions.

## download .rds:

Download the RDS file to use in the next step. There will be an
`example` column and a `data` column with a nested dataframe of object
properties. This will be used for automating accuracy calculations for
prompt engineering.

## download .xslx: 

Downloaded the examples as a unnested .xslx file.
This is commonly used to visualize the examples for accuracy. Note,
exporting to excel can mess with formats such as dates.

# Prompt Engineering

Step 3.

# Random sampling

Step 5.

# Validation

Step 6.

# Example 1: Extraction of Kidney Lesions form radiology reports

# Example 2: Extraction of Kidney Lesions form pathology reports
